import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color theme based on the design (Teal Green, Light Grey, White, etc.)
  static const Color primary = Color(0xFF16A394);      // The main Teal Green
  static const Color primaryDark = Color(0xFF0E6D68);  // Darker Teal for gradients
  static const Color background = Color(0xFFF8FAFB);   // Light Grey Background
  static const Color surface = Colors.white;           // Card White
  
  static const Color textDark = Color(0xFF0F172A);     // Main Headings (Black-ish)
  static const Color textGrey = Color(0xFF7A8A96);     // Subtitles (Grey)
  static const Color error = Color(0xFFE53935);        // Error Red
  
  static const Color softGreen = Color(0xFFE6F6F4);    // Light green bg for icons

  // Text styles based on the design (Poppins for headings, Inter for body)
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 26, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.5
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600, color: textDark
  );

  static TextStyle get bodyText => GoogleFonts.inter(
    fontSize: 14, color: textGrey, height: 1.5
  );

  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white
  );

  // Global theme data that can be applied to the entire app
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      
      // 1. Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryDark,
        surface: surface,
        background: background,
      ),

      // 2. Text Theme (Global Fonts)
      textTheme: TextTheme(
        displayLarge: headingLarge,
        titleLarge: headingMedium,
        bodyMedium: bodyText,
      ).apply(
        fontFamily: GoogleFonts.poppins().fontFamily,
        bodyColor: textDark,
        displayColor: textDark,
      ),

      // 3. Button Theme (Standard Green Button)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14), // Rounded corners from design
          ),
          textStyle: buttonText,
        ),
      ),

      // 4. Outlined Button Theme (White bg, Green border)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: buttonText.copyWith(color: primary),
        ),
      ),

      // 5. Input Fields (Search bars, text boxes)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // No border by default
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
      ),

      // 6. Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0, // Design uses shadows, not elevation
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}