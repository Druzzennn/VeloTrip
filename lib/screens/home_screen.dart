import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/copy.dart';
import '../models/challenge.dart';
import '../services/trip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/reveal_overlay.dart';
import '../widgets/snowfall.dart';
import 'bonus_km_screen.dart';
import 'challenge_detail_screen.dart';
import 'challenges_list_screen.dart';
import 'recap_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TripService>().refreshCalendar();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TripService>().refreshCalendar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripService>();
    final today = trip.todayChallenge;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.coldSky),
        child: Stack(
          children: [
            const Positioned.fill(child: Snowfall()),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _Header(trip: trip),
                  const SizedBox(height: 20),
                  _ProgressCard(trip: trip),
                  const SizedBox(height: 24),
                  if (today != null) _TodaySection(trip: trip, today: today),
                  const SizedBox(height: 24),
                  _NavTile(
                    icon: Icons.map_rounded,
                    title: 'Tous les défis',
                    subtitle:
                        '${trip.completedCount}/${trip.totalDays} validés • rattrapez les jours passés',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChallengesListScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _NavTile(
                    icon: Icons.auto_stories_rounded,
                    title: 'Carnet de voyage',
                    subtitle: trip.isTripFinished
                        ? 'Votre récap est prêt 🏆'
                        : 'Revivez l\'aventure jour par jour',
                    highlight: trip.isTripFinished,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecapScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TripService trip;
  const _Header({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FrostPedal',
                  style: Theme.of(context).textTheme.displayLarge),
              Text(
                'Jour ${trip.currentDay} sur ${trip.totalDays}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.glacier,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                contextualDayMessage(trip.currentDay, trip.totalDays),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
        _BikeBonusBadge(trip: trip),
      ],
    );
  }
}

class _BikeBonusBadge extends StatelessWidget {
  final TripService trip;
  const _BikeBonusBadge({required this.trip});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BonusKmScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = trip.bonusKmRemaining.round();
    final label = remaining > 0 ? '$remaining km' : '0 km';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🚲', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: remaining > 0 ? AppColors.amberDeep : AppColors.textMuted,
                ),
              ),
              Text(
                'bonus',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final TripService trip;
  const _ProgressCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du voyage',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.glacier,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '${(trip.progressFraction * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: trip.progressFraction,
              minHeight: 12,
              backgroundColor: AppColors.glacier.withValues(alpha: 0.3),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.amber),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${trip.completedCount} défi${trip.completedCount > 1 ? 's' : ''} relevé${trip.completedCount > 1 ? 's' : ''} sur ${trip.totalDays}',
            style: const TextStyle(color: AppColors.glacierLight, fontSize: 14),
          ),
          if (trip.currentStreak >= 2) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  '${trip.currentStreak} jours d\'affilée',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final TripService trip;
  final Challenge today;
  const _TodaySection({required this.trip, required this.today});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailScreen(day: today.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Défi du jour déjà validé
    if (today.completed) {
      return _Banner(
        emoji: '✅',
        title: today.title,
        subtitle: 'Défi du jour validé ! Rendez-vous demain.',
        buttonLabel: 'Revoir',
        onTap: () => _open(context),
      );
    }

    // Défi du jour pas encore révélé -> bouton héro de révélation
    if (!today.revealed) {
      return _RevealCard(
        onReveal: () async {
          await showRevealOverlay(context);
          if (!context.mounted) return;
          await trip.reveal(today);
          if (context.mounted) _open(context);
        },
      );
    }

    // Révélé mais pas encore complété
    return _Banner(
      emoji: '🔥',
      title: today.title,
      subtitle: today.description,
      buttonLabel: 'Continuer',
      onTap: () => _open(context),
    );
  }
}

class _RevealCard extends StatelessWidget {
  final Future<void> Function() onReveal;
  const _RevealCard({required this.onReveal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.warmGlow,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            'Un nouveau défi vous attend',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onReveal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.amberDeep,
              ),
              child: const Text('Découvrir le défi du jour'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _Banner({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onTap, child: Text(buttonLabel)),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: highlight ? AppColors.amber : AppColors.ice,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.ice,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.glacier),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
