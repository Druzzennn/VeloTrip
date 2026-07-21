import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/copy.dart';
import '../models/challenge.dart';
import '../services/trip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fullscreen_photo_viewer.dart';
import '../widgets/snowfall.dart';

/// Affiche un défi et permet de le valider via texte et/ou photo.
class ChallengeDetailScreen extends StatefulWidget {
  final int day;
  const ChallengeDetailScreen({super.key, required this.day});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  late final TextEditingController _textController;
  String? _photoPath;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final trip = context.read<TripService>();
    final c = trip.challenges.firstWhere((c) => c.day == widget.day);
    _textController = TextEditingController(text: c.textAnswer ?? '');
    _photoPath = c.photoPath;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final trip = context.read<TripService>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    final saved = await trip.persistPhoto(File(picked.path), widget.day);
    if (mounted) setState(() => _photoPath = saved);
  }

  bool get _canValidate =>
      _textController.text.trim().isNotEmpty ||
      (_photoPath != null && _photoPath!.isNotEmpty);

  Future<void> _validate(Challenge c) async {
    setState(() => _saving = true);
    final trip = context.read<TripService>();
    final wasCompleted = c.completed;
    await trip.completeChallenge(
      c,
      text: _textController.text,
      photoPath: _photoPath,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    HapticFeedback.mediumImpact();

    if (wasCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Défi mis à jour ✓')),
      );
      return;
    }

    final isFinal = c.day == trip.totalDays;
    await _showSuccess(c, totalDays: trip.totalDays, isFinalChallenge: isFinal);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showSuccess(
    Challenge c, {
    required int totalDays,
    required bool isFinalChallenge,
  }) async {
    final message = pickSuccessMessage(day: c.day);
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(28),
            border: isFinalChallenge
                ? Border.all(color: AppColors.amber, width: 3)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFinalChallenge ? '🏆❄️🎉' : '🎉❄️',
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(height: 12),
              Text(
                isFinalChallenge ? 'Voyage accompli !' : 'Défi validé !',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isFinalChallenge
                    ? 'Les $totalDays jours sont derrière vous. '
                        'Votre carnet de voyage est complet !'
                    : message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripService>();
    final c = trip.challenges.firstWhere((c) => c.day == widget.day);

    return Scaffold(
      appBar: AppBar(title: Text('Jour ${c.day}')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.coldSky),
        child: Stack(
          children: [
            const Positioned.fill(child: Snowfall()),
            SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _ChallengeHeader(challenge: c),
                  if (c.completed) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded,
                              color: AppColors.success, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Défi validé — vous pouvez modifier votre réponse.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text('Votre réponse',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Écrivez un mot, ajoutez une photo… ou les deux !',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _TextField(
                      controller: _textController, onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  _PhotoArea(
                    photoPath: _photoPath,
                    onCamera: () => _pickPhoto(ImageSource.camera),
                    onGallery: () => _pickPhoto(ImageSource.gallery),
                    onRemove: () => setState(() => _photoPath = null),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_canValidate && !_saving)
                          ? () => _validate(c)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: AppColors.locked,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(c.completed
                              ? 'Mettre à jour'
                              : 'Valider le défi'),
                    ),
                  ),
                  if (c.completed && c.completedAt != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Validé le ${DateFormat('d MMMM', 'fr_FR').format(c.completedAt!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeHeader extends StatelessWidget {
  final Challenge challenge;
  const _ChallengeHeader({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppTheme.warmGlow,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'DÉFI DU JOUR ${challenge.day}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(challenge.title,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(challenge.description,
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _TextField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Racontez votre exploit du jour…',
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.ice, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.ice, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.glacier, width: 2),
        ),
      ),
    );
  }
}

class _PhotoArea extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoArea({
    required this.photoPath,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && photoPath!.isNotEmpty) {
      return Stack(
        children: [
          GestureDetector(
            onTap: () => showFullscreenPhoto(context, photoPath!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(
                File(photoPath!),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onRemove,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: _PhotoButton(
            icon: Icons.photo_camera_rounded,
            label: 'Photo',
            onTap: onCamera,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PhotoButton(
            icon: Icons.image_rounded,
            label: 'Galerie',
            onTap: onGallery,
          ),
        ),
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.ice, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.glacier, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
