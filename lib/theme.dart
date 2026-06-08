// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary       = Color(0xFF1E40AF);
  static const Color primaryLight  = Color(0xFF3B82F6);
  static const Color secondary     = Color(0xFF0F766E);
  static const Color accent        = Color(0xFF7C3AED);
  static const Color background    = Color(0xFFF1F5F9);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color sidebar       = Color(0xFF0F172A);
  static const Color sidebarActive = Color(0xFF1E3A8A);
  static const Color success       = Color(0xFF22C55E);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color error         = Color(0xFFEF4444);
  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border        = Color(0xFFE2E8F0);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: background,
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class AppConstants {
  static const List<String> equipmentStatuses   = ['active', 'inactive', 'under_repair', 'disposed'];
  static const List<String> equipmentConditions = ['excellent', 'good', 'fair', 'poor'];
  static const List<String> borrowingStatuses   = ['pending', 'borrowed', 'returned', 'overdue', 'lost'];
  static const List<String> maintenanceTypes    = ['preventive', 'corrective', 'inspection'];
  static const List<String> maintenanceStatuses = ['scheduled', 'in_progress', 'completed', 'cancelled'];

  static Color statusColor(String status) {
    switch (status) {
      case 'active':      case 'returned':  case 'completed':  return AppTheme.success;
      case 'inactive':    case 'cancelled':                    return AppTheme.textSecondary;
      case 'under_repair':case 'in_progress':case 'borrowed':  return AppTheme.warning;
      case 'disposed':    case 'overdue':   case 'lost':       return AppTheme.error;
      case 'pending':                                          return AppTheme.primaryLight;
      case 'scheduled':                                        return AppTheme.primaryLight;
      case 'excellent':                                        return AppTheme.success;
      case 'good':                                             return AppTheme.primaryLight;
      case 'fair':                                             return AppTheme.warning;
      case 'poor':                                             return AppTheme.error;
      default: return AppTheme.textSecondary;
    }
  }

  static String formatStatus(String status) {
    return status.split('_').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
  }
}