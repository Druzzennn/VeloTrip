import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/bonus_km.dart';
import '../services/trip_service.dart';
import '../theme/app_theme.dart';
import '../widgets/snowfall.dart';

class BonusKmScreen extends StatefulWidget {
  const BonusKmScreen({super.key});

  @override
  State<BonusKmScreen> createState() => _BonusKmScreenState();
}

class _BonusKmScreenState extends State<BonusKmScreen> {
  int _kmToAdd = 0;

  void _adjust(int delta) {
    setState(() => _kmToAdd = (_kmToAdd + delta).clamp(0, 999));
  }

  Future<void> _save(TripService trip) async {
    if (_kmToAdd <= 0) return;
    final saved = _kmToAdd;
    await trip.addBonusKmRidden(saved.toDouble());
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _kmToAdd = 0);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$saved km enregistrés')));
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripService>();
    final days = trip.penalizedDays;
    final remaining = trip.bonusKmRemaining;

    return Scaffold(
      appBar: AppBar(title: const Text('Kilomètres bonus')),
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.ice, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étape supplémentaire',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chaque défi non validé le jour même ajoute '
                          '$bonusKmPerMissedDay km supplémentaires à rouler. ',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(trip: trip),
                  const SizedBox(height: 24),
                  Text(
                    'Détail par jour',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (days.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.ice, width: 2),
                      ),
                      child: Text(
                        'Aucun kilomètre bonus en suspens pour l\'instant. '
                        'Continuez à valider vos défis chaque jour ! 🚲',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  else
                    ...days.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DayRow(day: d),
                      ),
                    ),
                  if (trip.bonusKmDue > 0) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Enregistrer mes km',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Indiquez combien de kilomètres vous avez roulé sur votre étape bonus.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.ice, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StepButton(
                                label: '−5',
                                onTap: () => _adjust(-5),
                              ),
                              const SizedBox(width: 8),
                              _StepButton(
                                label: '−1',
                                onTap: () => _adjust(-1),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '$_kmToAdd km',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppColors.glacier),
                              ),
                              const SizedBox(width: 16),
                              _StepButton(label: '+1', onTap: () => _adjust(1)),
                              const SizedBox(width: 8),
                              _StepButton(label: '+5', onTap: () => _adjust(5)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _kmToAdd > 0 && remaining > 0
                                  ? () => _save(trip)
                                  : null,
                              child: const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (remaining <= 0 && trip.bonusKmDue > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Tous vos kilomètres bonus sont honorés. Belle route ! 🚲',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
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

class _SummaryCard extends StatelessWidget {
  final TripService trip;
  const _SummaryCard({required this.trip});

  String _fmt(double v) {
    if (v == v.roundToDouble()) return '${v.round()} km';
    return '${v.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'Dû',
              value: _fmt(trip.bonusKmDue.toDouble()),
            ),
          ),
          Expanded(
            child: _SummaryStat(
              label: 'Roulé',
              value: _fmt(trip.bonusKmRidden),
            ),
          ),
          Expanded(
            child: _SummaryStat(
              label: 'Restant',
              value: _fmt(trip.bonusKmRemaining),
              highlight: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.amber : AppColors.glacier,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.glacierLight, fontSize: 13),
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final int day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ice, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.ice,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Jour $day',
              style: const TextStyle(
                color: AppColors.glacier,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Défi non validé à temps',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            '+$bonusKmPerMissedDay km supp.',
            style: const TextStyle(
              color: AppColors.amberDeep,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ice,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.glacier,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
