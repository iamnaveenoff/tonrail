import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rams audio panel: matte anthracite enclosure, warm-grey legends, one signal
/// orange for the active state and one green "running" dot for the link.
class AppTheme {
  static const font = 'Archivo';

  /// Corner language: soft-shouldered hardware keys; pills only for selection.
  static const radius = 12.0;
  static const radiusLarge = 16.0;

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFEE6A24),
    onPrimary: Color(0xFF1A0D05),
    primaryContainer: Color(0xFF3A2214),
    onPrimaryContainer: Color(0xFFFFD3BB),
    secondary: Color(0xFFCFCAC1),
    onSecondary: Color(0xFF1C1C1B),
    secondaryContainer: Color(0xFF2E2D2A),
    onSecondaryContainer: Color(0xFFE6E2DA),
    tertiary: Color(0xFF74B884),
    onTertiary: Color(0xFF0C2412),
    tertiaryContainer: Color(0xFF1B3322),
    onTertiaryContainer: Color(0xFFBFE6C8),
    error: Color(0xFFFF8B7A),
    onError: Color(0xFF3B0A04),
    errorContainer: Color(0xFF4A1C15),
    onErrorContainer: Color(0xFFFFDAD3),
    surface: Color(0xFF1E1F1F),
    onSurface: Color(0xFFECE8E1),
    surfaceDim: Color(0xFF171818),
    surfaceBright: Color(0xFF424343),
    surfaceContainerLowest: Color(0xFF171818),
    surfaceContainerLow: Color(0xFF262727),
    surfaceContainer: Color(0xFF2B2C2C),
    surfaceContainerHigh: Color(0xFF333434),
    surfaceContainerHighest: Color(0xFF3C3D3D),
    onSurfaceVariant: Color(0xFFB0ABA2),
    outline: Color(0xFF6E6A63),
    outlineVariant: Color(0xFF404141),
    inverseSurface: Color(0xFFECE8E1),
    onInverseSurface: Color(0xFF1C1C1B),
    inversePrimary: Color(0xFFB6461A),
    shadow: Color(0xFF000000),
  );

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFB6461A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF7D9C8),
    onPrimaryContainer: Color(0xFF3A1406),
    secondary: Color(0xFF55524C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE2DED6),
    onSecondaryContainer: Color(0xFF1C1C1B),
    tertiary: Color(0xFF2F7A42),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFCBEBD2),
    onTertiaryContainer: Color(0xFF07210E),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: Color(0xFFE8E5DE),
    onSurface: Color(0xFF1C1C1B),
    surfaceDim: Color(0xFFD9D5CD),
    surfaceBright: Color(0xFFFFFFFF),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFEFEDE8),
    surfaceContainer: Color(0xFFF4F2EE),
    surfaceContainerHigh: Color(0xFFFAF9F6),
    surfaceContainerHighest: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xFF5A564F),
    outline: Color(0xFF8C877E),
    outlineVariant: Color(0xFFD2CEC5),
    inverseSurface: Color(0xFF292927),
    onInverseSurface: Color(0xFFECE8E1),
    inversePrimary: Color(0xFFEE6A24),
    shadow: Color(0xFF000000),
  );

  static ThemeData dark() => _build(_darkScheme);
  static ThemeData light() => _build(_lightScheme);

  static ThemeData _build(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    final base = ThemeData(colorScheme: s, useMaterial3: true, fontFamily: font);
    final b = base.textTheme;
    final text = b
        .copyWith(
          displayLarge: b.displayLarge?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -1.2),
          displayMedium: b.displayMedium?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -1.0),
          displaySmall: b.displaySmall?.copyWith(fontWeight: FontWeight.w500, letterSpacing: -0.8),
          headlineLarge: b.headlineLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.6),
          headlineMedium: b.headlineMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5),
          headlineSmall: b.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleLarge: b.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleMedium: b.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
          titleSmall: b.titleSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
          bodyLarge: b.bodyLarge?.copyWith(letterSpacing: 0.1),
          bodyMedium: b.bodyMedium?.copyWith(letterSpacing: 0.1),
          bodySmall: b.bodySmall?.copyWith(letterSpacing: 0.2),
          labelLarge: b.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.3),
          labelMedium: b.labelMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.4),
          labelSmall: b.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1.4),
        )
        .apply(bodyColor: s.onSurface, displayColor: s.onSurface);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    const minTap = Size(52, 52);

    return base.copyWith(
      scaffoldBackgroundColor: s.surface,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlay(s),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: s.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: s.primary.withValues(alpha: dark ? 0.18 : 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (st) => IconThemeData(size: 22, color: st.contains(WidgetState.selected) ? s.primary : s.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (st) => text.labelMedium?.copyWith(
            letterSpacing: 0.2,
            color: st.contains(WidgetState.selected) ? s.onSurface : s.onSurfaceVariant,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: s.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: s.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: shape,
        side: BorderSide(color: s.outlineVariant),
        backgroundColor: s.surfaceContainerLow,
        selectedColor: s.primary,
        disabledColor: s.surfaceContainerLow,
        labelStyle: text.labelLarge,
        secondaryLabelStyle: text.labelLarge?.copyWith(color: s.onPrimary),
        checkmarkColor: s.onPrimary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: s.primary,
        inactiveTrackColor: s.outlineVariant,
        thumbColor: s.onSurface,
        overlayColor: s.primary.withValues(alpha: 0.12),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 1, pressedElevation: 2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        valueIndicatorColor: s.inverseSurface,
        valueIndicatorTextStyle: text.labelMedium?.copyWith(color: s.onInverseSurface),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((st) {
          if (st.contains(WidgetState.disabled)) return s.outline.withValues(alpha: 0.5);
          return st.contains(WidgetState.selected) ? s.onPrimary : s.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((st) {
          if (st.contains(WidgetState.disabled)) return s.surfaceContainerHigh;
          return st.contains(WidgetState.selected) ? s.primary : s.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected) ? Colors.transparent : s.outlineVariant,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: s.inverseSurface,
          foregroundColor: s.onInverseSurface,
          disabledBackgroundColor: s.surfaceContainerHigh,
          shape: shape,
          minimumSize: minTap,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: shape,
          minimumSize: minTap,
          foregroundColor: s.onSurface,
          side: BorderSide(color: s.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: shape,
          minimumSize: minTap,
          foregroundColor: s.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: minTap, shape: shape),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: s.onSurfaceVariant,
        minVerticalPadding: 12,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall?.copyWith(color: s.onSurfaceVariant),
        selectedColor: s.primary,
        shape: shape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLarge + 4)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: s.outline,
        dragHandleSize: const Size(36, 4),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge + 6))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: s.outlineVariant),
        ),
        textStyle: text.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: s.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: s.onInverseSurface),
        actionTextColor: dark ? s.inversePrimary : s.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius + 2)),
        elevation: 2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: s.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: s.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: s.primary,
        selectionColor: s.primary.withValues(alpha: 0.3),
        selectionHandleColor: s.primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: s.inverseSurface, borderRadius: BorderRadius.circular(radius)),
        textStyle: text.bodySmall?.copyWith(color: s.onInverseSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: s.primary),
      dividerTheme: DividerThemeData(color: s.outlineVariant, space: 1, thickness: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }

  static SystemUiOverlayStyle overlay(ColorScheme s) {
    final dark = s.brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: s.brightness,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }
}

const tabular = [FontFeature.tabularFigures()];
