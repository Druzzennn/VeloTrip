import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/challenge.dart';
import '../services/trip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/snowfall.dart';
import '../widgets/stamp_badge.dart';
import 'challenge_detail_screen.dart';

class ChallengesListScreen extends StatelessWidget {
  const ChallengesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tous les défis')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.coldSky),
        child: Stack(
          children: [
            const Positioned.fill(child: Snowfall()),
            SafeArea(
              top: false,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                itemCount: trip.totalDays,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final c = trip.challenges[i];
                  final unlocked = trip.isUnlocked(c);
                  return _ChallengeRow(
                    challenge: c,
                    unlocked: unlocked,
                    missed: trip.isMissed(c),
                    onTap: unlocked
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChallengeDetailScreen(day: c.day),
                              ),
                            )
                        : () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Ce défi se débloquera au jour ${c.day} 🔒',
                                ),
                              ),
                            ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeRow extends StatelessWidget {
  final Challenge challenge;
  final bool unlocked;
  final bool missed;
  final VoidCallback onTap;

  const _ChallengeRow({
    required this.challenge,
    required this.unlocked,
    required this.missed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = challenge.completed;
    final IconData icon;
    final Color iconColor;
    final String status;

    if (completed) {
      icon = Icons.check_circle_rounded;
      iconColor = AppColors.success;
      status = 'Validé';
    } else if (unlocked) {
      icon = Icons.lock_open_rounded;
      iconColor = missed ? AppColors.amber : AppColors.glacier;
      status = missed ? 'À rattraper' : 'À relever';
    } else {
      icon = Icons.lock_rounded;
      iconColor = AppColors.locked;
      status = 'Verrouillé';
    }

    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: completed
                    ? AppColors.success
                    : missed
                        ? AppColors.amber.withValues(alpha: 0.6)
                        : AppColors.ice,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ice,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${challenge.day}',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppColors.glacier),
                      ),
                    ),
                    if (missed)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.amber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unlocked ? challenge.title : 'Défi du jour ${challenge.day}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(status,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (completed)
                  const StampBadge(size: 34)
                else
                  Icon(icon, color: iconColor, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
