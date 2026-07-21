import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/trip_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  final trip = TripService();
  await trip.init();

  runApp(
    ChangeNotifierProvider.value(
      value: trip,
      child: const FrostPedalApp(),
    ),
  );
}

class FrostPedalApp extends StatelessWidget {
  const FrostPedalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrostPedal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Root(),
    );
  }
}

/// Aiguille vers l'onboarding (1er lancement) ou l'accueil.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripService>();
    if (!trip.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return trip.hasStarted ? const HomeScreen() : const OnboardingScreen();
  }
}
