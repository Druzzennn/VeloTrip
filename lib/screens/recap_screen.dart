import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../services/share_service.dart';
import '../services/trip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fullscreen_photo_viewer.dart';
import '../widgets/snowfall.dart';
import 'challenge_detail_screen.dart';

class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripService>();
    final done = trip.challenges.where((c) => c.completed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Carnet de voyage')),
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
                  _RecapHeader(trip: trip),
                  const SizedBox(height: 24),
                  if (done.isEmpty)
                    _EmptyState()
                  else ...[
                    Text('Votre aventure',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Chaque défi relevé, dans l\'ordre.',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    ...done.map((c) => _TimelineEntry(challenge: c)),
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

class _RecapHeader extends StatelessWidget {
  final TripService trip;
  const _RecapHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final finished = trip.allCompleted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Column(
        children: [
          Text(finished ? '🏆' : '🗺️', style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          Text(
            finished ? 'Voyage accompli !' : 'En cours d\'aventure',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(value: '${trip.completedCount}', label: 'défis relevés'),
              _Stat(value: '${trip.totalDays}', label: 'jours de voyage'),
              _Stat(
                value:
                    '${trip.challenges.where((c) => c.hasPhoto).length}',
                label: 'photos',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                color: AppColors.glacierLight, fontSize: 12)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Column(
        children: [
          const Text('❄️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'Aucun défi validé pour l\'instant.\nRelevez votre premier défi pour commencer le carnet !',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final Challenge challenge;
  const _TimelineEntry({required this.challenge});

  Future<void> _share(BuildContext context, Rect? origin) async {
    await ShareService.shareChallenge(
      context: context,
      day: challenge.day,
      title: challenge.title,
      description: challenge.description,
      textAnswer: challenge.textAnswer,
      completedAt: challenge.completedAt,
      photoPath: challenge.photoPath,
      shareOrigin: origin,
    );
  }

  void _edit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(day: challenge.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (challenge.hasPhoto)
            GestureDetector(
              onTap: () => showFullscreenPhoto(context, challenge.photoPath!),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.file(
                  File(challenge.photoPath!),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.ice,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Jour ${challenge.day}',
                        style: const TextStyle(
                          color: AppColors.glacier,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (challenge.completedAt != null)
                      Text(
                        DateFormat('d MMM', 'fr_FR')
                            .format(challenge.completedAt!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: AppColors.glacier, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Modifier',
                      onPressed: () => _edit(context),
                    ),
                    Builder(
                      builder: (btnContext) => IconButton(
                        icon: const Icon(Icons.share_rounded,
                            color: AppColors.glacier, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Partager',
                        onPressed: () {
                          final box =
                              btnContext.findRenderObject() as RenderBox?;
                          final origin = box != null
                              ? box.localToGlobal(Offset.zero) & box.size
                              : null;
                          _share(context, origin);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(challenge.title,
                    style: Theme.of(context).textTheme.titleLarge),
                if (challenge.hasText) ...[
                  const SizedBox(height: 6),
                  Text(challenge.textAnswer!,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
