import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/bonus_km.dart';
import '../data/challenges_data.dart';
import '../models/challenge.dart';

/// Gère tout l'état du voyage et sa persistance locale (aucun cloud).
/// - date de départ -> SharedPreferences
/// - progression des défis -> fichier JSON dans le dossier de l'app
/// - photos -> copiées dans le dossier de l'app
class TripService extends ChangeNotifier {
  static const _kStartDateKey = 'trip_start_date';

  DateTime? _startDate;
  final List<Challenge> _challenges = buildChallenges();
  final List<int> _penalizedDays = [];
  double _bonusKmRidden = 0;
  int _lastSyncedDay = 0;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get hasStarted => _startDate != null;
  DateTime? get startDate => _startDate;
  List<Challenge> get challenges => List.unmodifiable(_challenges);
  int get totalDays => _challenges.length;

  /// Jour courant du voyage (1-based), borné à [1, totalDays].
  /// Renvoie 0 si le voyage n'a pas commencé.
  int get currentDay {
    if (_startDate == null) return 0;
    final start = _dateOnly(_startDate!);
    final today = _dateOnly(DateTime.now());
    final diff = today.difference(start).inDays + 1;
    if (diff < 1) return 1; // départ dans le futur -> on est au jour 1
    if (diff > totalDays) return totalDays;
    return diff;
  }

  bool isUnlocked(Challenge c) => hasStarted && c.day <= currentDay;

  /// Le défi rattaché au jour courant.
  Challenge? get todayChallenge {
    if (!hasStarted) return null;
    return _challenges.firstWhere((c) => c.day == currentDay);
  }

  int get completedCount => _challenges.where((c) => c.completed).length;

  double get progressFraction =>
      totalDays == 0 ? 0 : completedCount / totalDays;

  /// Le voyage est "terminé" quand le dernier jour est atteint.
  bool get isTripFinished => hasStarted && currentDay >= totalDays;

  bool get allCompleted => completedCount == totalDays;

  /// Jours consécutifs validés en remontant depuis le jour courant (ou la veille).
  int get currentStreak {
    if (!hasStarted) return 0;
    final today = todayChallenge;
    var day = (today != null && today.completed) ? currentDay : currentDay - 1;
    var streak = 0;
    while (day >= 1) {
      final c = _challenges.firstWhere((ch) => ch.day == day);
      if (!c.completed) break;
      streak++;
      day--;
    }
    return streak;
  }

  /// Défi débloqué mais non validé, et le jour est passé.
  bool isMissed(Challenge c) =>
      isUnlocked(c) && !c.completed && c.day < currentDay;

  /// Jours ayant généré des km bonus (défi non validé le jour même).
  List<int> get penalizedDays =>
      List<int>.from(_penalizedDays)..sort();

  int get bonusKmDue => _penalizedDays.length * bonusKmPerMissedDay;

  double get bonusKmRidden => _bonusKmRidden;

  double get bonusKmRemaining {
    final left = bonusKmDue - _bonusKmRidden;
    return left > 0 ? left : 0;
  }

  bool get hasBonusKmDebt => bonusKmRemaining > 0;

  /// Enregistre des km roulés sur l'étape bonus (cumulatif).
  Future<void> addBonusKmRidden(double km) async {
    if (km <= 0) return;
    _bonusKmRidden += km;
    await _saveBonusKm();
    notifyListeners();
  }

  /// Recalcule les jours pénalisés si le jour calendaire a changé (ex. après minuit).
  void refreshCalendar() {
    if (!hasStarted) return;
    final penalizedBefore = _penalizedDays.length;
    final day = currentDay;
    _syncPenalizedDays();
    if (day != _lastSyncedDay || _penalizedDays.length != penalizedBefore) {
      _lastSyncedDay = day;
      notifyListeners();
    }
  }

  // ----- Chargement / sauvegarde -----

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kStartDateKey);
    if (stored != null) {
      _startDate = DateTime.tryParse(stored);
    }
    await _loadProgress();
    await _loadBonusKm();
    _syncPenalizedDays();
    _lastSyncedDay = currentDay;
    _loaded = true;
    notifyListeners();
  }

  Future<void> startTrip(DateTime date) async {
    _startDate = _dateOnly(date);
    _bonusKmRidden = 0;
    _penalizedDays.clear();
    _lastSyncedDay = currentDay;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStartDateKey, _startDate!.toIso8601String());
    final bonusFile = await _bonusKmFile;
    if (bonusFile.existsSync()) bonusFile.deleteSync();
    notifyListeners();
  }

  /// Marque un défi comme découvert (animation de révélation côté UI).
  Future<void> reveal(Challenge c) async {
    if (c.revealed) return;
    c.revealed = true;
    await _saveProgress();
    notifyListeners();
  }

  /// Valide un défi avec un texte et/ou une photo (au moins l'un des deux).
  Future<void> completeChallenge(
    Challenge c, {
    String? text,
    String? photoPath,
  }) async {
    c.textAnswer = (text != null && text.trim().isNotEmpty) ? text.trim() : null;
    c.photoPath = (photoPath != null && photoPath.isNotEmpty) ? photoPath : null;
    c.completed = c.hasText || c.hasPhoto;
    if (c.completed && c.completedAt == null) {
      c.completedAt = DateTime.now();
    } else if (!c.completed) {
      c.completedAt = null;
    }
    if (c.completed) c.revealed = true;
    await _saveProgress();
    _syncPenalizedDays();
    notifyListeners();
  }

  /// Copie une photo choisie dans le dossier de l'app et renvoie le chemin local.
  Future<String> persistPhoto(File source, int day) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${dir.path}/photos');
    if (!photosDir.existsSync()) {
      photosDir.createSync(recursive: true);
    }
    final ext = source.path.split('.').last;
    final dest = File(
      '${photosDir.path}/defi_${day}_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await source.copy(dest.path);
    return dest.path;
  }

  Future<File> get _progressFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/progress.json');
  }

  Future<File> get _bonusKmFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/bonus_km.json');
  }

  void _syncPenalizedDays() {
    _penalizedDays.clear();
    if (_startDate == null) return;
    for (var d = 1; d < currentDay; d++) {
      final c = _challenges.firstWhere((ch) => ch.day == d);
      final dueDate = _dateOnly(_startDate!).add(Duration(days: d - 1));
      if (_dayIncursBonus(c, dueDate)) {
        _penalizedDays.add(d);
      }
    }
  }

  bool _dayIncursBonus(Challenge c, DateTime dueDate) {
    if (!c.completed) return true;
    if (c.completedAt == null) return true;
    return _dateOnly(c.completedAt!).isAfter(dueDate);
  }

  Future<void> _loadBonusKm() async {
    try {
      final file = await _bonusKmFile;
      if (!file.existsSync()) return;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _bonusKmRidden = (map['bonusKmRidden'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      _bonusKmRidden = 0;
    }
  }

  Future<void> _saveBonusKm() async {
    final file = await _bonusKmFile;
    await file.writeAsString(jsonEncode({'bonusKmRidden': _bonusKmRidden}));
  }

  Future<void> _loadProgress() async {
    try {
      final file = await _progressFile;
      if (!file.existsSync()) return;
      final raw = jsonDecode(await file.readAsString()) as List<dynamic>;
      for (final entry in raw) {
        final map = entry as Map<String, dynamic>;
        final day = map['day'] as int?;
        if (day == null) continue;
        final match = _challenges.where((c) => c.day == day);
        if (match.isNotEmpty) match.first.applyProgress(map);
      }
    } catch (_) {
      // Fichier corrompu : on repart sur une progression vide plutôt que de crasher.
    }
  }

  Future<void> _saveProgress() async {
    final file = await _progressFile;
    final data = _challenges.map((c) => c.progressToJson()).toList();
    await file.writeAsString(jsonEncode(data));
  }

  /// Réinitialise tout le voyage (utile pour les tests / un nouveau voyage).
  Future<void> resetTrip() async {
    _startDate = null;
    for (final c in _challenges) {
      c.revealed = false;
      c.completed = false;
      c.textAnswer = null;
      c.photoPath = null;
      c.completedAt = null;
    }
    _penalizedDays.clear();
    _bonusKmRidden = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStartDateKey);
    final file = await _progressFile;
    if (file.existsSync()) file.deleteSync();
    final bonusFile = await _bonusKmFile;
    if (bonusFile.existsSync()) bonusFile.deleteSync();
    notifyListeners();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
