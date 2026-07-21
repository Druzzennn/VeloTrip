/// Un défi du voyage : sa définition (jour, titre, description)
/// + l'état de progression (révélé, complété, réponse texte/photo).
class Challenge {
  /// Numéro du jour (1-based). Le défi du jour N se débloque le jour N du voyage.
  final int day;
  final String title;
  final String description;

  // --- Progression (persistée) ---
  bool revealed;
  bool completed;
  String? textAnswer;
  String? photoPath;
  DateTime? completedAt;

  Challenge({
    required this.day,
    required this.title,
    required this.description,
    this.revealed = false,
    this.completed = false,
    this.textAnswer,
    this.photoPath,
    this.completedAt,
  });

  bool get hasText => textAnswer != null && textAnswer!.trim().isNotEmpty;
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  /// Seule la partie "progression" est sauvegardée ;
  /// la définition (titre/description) vient des données statiques.
  Map<String, dynamic> progressToJson() => {
        'day': day,
        'revealed': revealed,
        'completed': completed,
        'textAnswer': textAnswer,
        'photoPath': photoPath,
        'completedAt': completedAt?.toIso8601String(),
      };

  void applyProgress(Map<String, dynamic> json) {
    revealed = json['revealed'] as bool? ?? false;
    completed = json['completed'] as bool? ?? false;
    textAnswer = json['textAnswer'] as String?;
    photoPath = json['photoPath'] as String?;
    final completedRaw = json['completedAt'] as String?;
    completedAt = completedRaw != null ? DateTime.tryParse(completedRaw) : null;
  }
}
