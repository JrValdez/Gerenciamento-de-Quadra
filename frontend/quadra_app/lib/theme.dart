import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Paleta da marca — verde "quadra" com âmbar de destaque (energia esportiva).
class Brand {
  static const green = Color(0xFF1B7A3D);
  static const greenDark = Color(0xFF0E5A2C);
  static const greenSoft = Color(0xFFE7F3EB);
  static const amber = Color(0xFFF59E0B);
  static const ink = Color(0xFF0F1E17);
  static const slate = Color(0xFF5B6B63);
  static const bg = Color(0xFFF3F6F4);
  static const border = Color(0xFFE1E8E3);
  static const danger = Color(0xFFDC2626);

  /// Gradiente usado nos destaques/hero.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B7A3D), Color(0xFF0E5A2C)],
  );
}

ThemeData _build() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.green,
    brightness: Brightness.light,
  ).copyWith(
    primary: Brand.green,
    onPrimary: Colors.white,
    secondary: Brand.amber,
    surface: Colors.white,
    onSurface: Brand.ink,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF8FAF9),
    outlineVariant: Brand.border,
    error: Brand.danger,
  );

  // Barlow no corpo, Barlow Condensed nos títulos (esportivo, direto).
  final base = ThemeData.light(useMaterial3: true).textTheme;
  final body = GoogleFonts.barlowTextTheme(base);
  TextStyle cond(double size, FontWeight w, {double spacing = 0, Color? color}) =>
      GoogleFonts.barlowCondensed(
          fontSize: size, fontWeight: w, letterSpacing: spacing, color: color ?? Brand.ink, height: 1.1);

  final textTheme = body.copyWith(
    displaySmall: cond(40, FontWeight.w700),
    headlineMedium: cond(32, FontWeight.w700),
    headlineSmall: cond(26, FontWeight.w700),
    titleLarge: cond(22, FontWeight.w600),
    titleMedium: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.w600, color: Brand.ink),
    bodyLarge: GoogleFonts.barlow(fontSize: 15, color: Brand.ink, height: 1.45),
    bodyMedium: GoogleFonts.barlow(fontSize: 14, color: Brand.ink, height: 1.45),
    labelLarge: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: Brand.bg,
    dividerColor: Brand.border,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Colors.white,
      foregroundColor: Brand.ink,
      titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 22, fontWeight: FontWeight.w700, color: Brand.ink),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7FAF8),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Brand.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Brand.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Brand.green, width: 1.6),
      ),
      labelStyle: const TextStyle(color: Brand.slate),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.barlow(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.green,
        side: const BorderSide(color: Brand.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.barlow(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Brand.green),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Brand.green,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      side: const BorderSide(color: Brand.border),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Brand.greenSoft,
      selectedIconTheme: const IconThemeData(color: Brand.green),
      unselectedIconTheme: const IconThemeData(color: Brand.slate),
      selectedLabelTextStyle: GoogleFonts.barlow(color: Brand.green, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: GoogleFonts.barlow(color: Brand.slate),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      // Inset menor para o diálogo aproveitar mais a largura em telas de celular.
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(GoogleFonts.barlow(fontWeight: FontWeight.w600)),
      ),
    ),
  );
}

final ThemeData appTheme = _build();

final moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final dataHora = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
final dataFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
final horaFmt = DateFormat('HH:mm', 'pt_BR');

/// Largura responsiva para o conteúdo de um diálogo: usa [max] em telas largas e
/// encolhe até caber nas menores, evitando overflow horizontal no celular.
/// Desconta a inset do diálogo (16*2) e o padding interno do AlertDialog (24*2).
double dialogW(BuildContext context, [double max = 460]) {
  final disponivel = MediaQuery.sizeOf(context).width - 80;
  return disponivel < max ? disponivel : max;
}

/// Altura responsiva para diálogos de altura fixa (não estoura em telas baixas).
double dialogH(BuildContext context, double max) {
  final disponivel = MediaQuery.sizeOf(context).height - 200;
  return disponivel < max ? disponivel : max;
}

/// Ponto de corte: abaixo disso usamos layout de celular (menu em gaveta).
bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < 800;
