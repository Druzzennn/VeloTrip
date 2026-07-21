import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/trip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/snowfall.dart';

/// Premier lancement : on demande la date de départ du voyage.
/// C'est elle qui définit le "Jour 1" et le rythme d'un défi par jour.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final trip = context.read<TripService>();
    final dateLabel =
        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selected);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.coldSky),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Snowfall(flakeCount: 120, intensity: 1.65),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    const Text('🚲❄️', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 20),
                    Text(
                      'FrostPedal',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Un défi par jour, tout au long de votre '
                      'aventure à vélo dans le Grand Nord.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Quand commence le voyage ?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _DatePickerCard(
                      label: dateLabel,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selected,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          locale: const Locale('fr', 'FR'),
                        );
                        if (picked != null) {
                          setState(() => _selected = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Astuce : vous pourrez quand même rattraper les défis '
                      'des jours précédents à tout moment.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await trip.startTrip(_selected);
                        },
                        child: const Text('C\'est parti !'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DatePickerCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: AppColors.glacier),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.edit_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
