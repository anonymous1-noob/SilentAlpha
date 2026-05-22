import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primary = Color(0xFF6C63FF);
  static const _primaryDark = Color(0xFF4A42D6);
  static const _secondary = Color(0xFFFF6B9D);
  static const _surface = Color(0xFF1A1A2E);
  static const _surfaceVariant = Color(0xFF16213E);
  static const _cardBg = Color(0xFF0F3460);
  static const _onSurface = Color(0xFFE8E8F0);
  static const _onSurfaceMuted = Color(0xFF9898B0);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _primary,
        secondary: _secondary,
        surface: _surface,
        onSurface: _onSurface,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: _surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: _onSurface, displayColor: _onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceVariant,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: _onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: _onSurface),
      ),
      cardTheme: CardThemeData(
        color: _cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        hintStyle: const TextStyle(color: _onSurfaceMuted),
        labelStyle: const TextStyle(color: _onSurfaceMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceVariant,
        selectedItemColor: _primary,
        unselectedItemColor: _onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A4A),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _surfaceVariant,
        selectedColor: _primary,
        labelStyle: const TextStyle(color: _onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static const primary = _primary;
  static const primaryDark = _primaryDark;
  static const secondary = _secondary;
  static const surface = _surface;
  static const surfaceVariant = _surfaceVariant;
  static const cardBg = _cardBg;
  static const onSurface = _onSurface;
  static const onSurfaceMuted = _onSurfaceMuted;

  static const gradient = LinearGradient(
    colors: [_primary, _secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
