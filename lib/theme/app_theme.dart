import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette "Expédition nordique illustrée" :
/// bleus glaciers + blancs neige + un accent chaud (ambre/phare)
/// et une touche vert sapin pour le côté aventure.
class AppColors {
  // Bleus glaciers
  static const Color deepBlue = Color(0xFF14304A); // texte / nuit polaire
  static const Color glacier = Color(0xFF3E78B5); // bleu principal
  static const Color glacierLight = Color(0xFF8FBCE0);
  static const Color ice = Color(0xFFE9F2F9); // surfaces froides

  // Neige / fonds
  static const Color snow = Color(0xFFF6FAFD);
  static const Color white = Color(0xFFFFFFFF);

  // Accent chaud (lumière de phare)
  static const Color amber = Color(0xFFF5A623);
  static const Color amberDeep = Color(0xFFE8841C);

  // Vert sapin (aventure)
  static const Color pine = Color(0xFF2E7D6B);

  // États
  static const Color success = Color(0xFF3DAE7C);
  static const Color locked = Color(0xFFB7C5D1);

  // Texte
  static const Color textDark = Color(0xFF14304A);
  static const Color textMuted = Color(0xFF6B8199);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    // Titres ronds & fun (Fredoka) + corps lisible (Nunito)
    final textTheme = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.fredoka(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBlue,
      ),
      headlineMedium: GoogleFonts.fredoka(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.deepBlue,
      ),
      titleLarge: GoogleFonts.fredoka(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: AppColors.deepBlue,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        color: AppColors.textDark,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        color: AppColors.textMuted,
        height: 1.4,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.snow,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.glacier,
        secondary: AppColors.amber,
        surface: AppColors.white,
        onPrimary: AppColors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fredoka(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.deepBlue,
        ),
        iconTheme: const IconThemeData(color: AppColors.deepBlue),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.glacier,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.fredoka(
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Dégradé "ciel froid" utilisé en fond des écrans clés.
  static const LinearGradient coldSky = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFDCEBF7), AppColors.snow],
  );

  /// Dégradé du bouton héro (lumière de phare).
  static const LinearGradient warmGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.amber, AppColors.amberDeep],
  );
}
