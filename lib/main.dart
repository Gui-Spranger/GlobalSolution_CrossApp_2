import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'screens/home_screen.dart';
import 'services.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await Storage.open();
  final state = AppState(storage, WeatherApi());
  unawaited(state.init()); // abre o app sem esperar a internet

  runApp(ChangeNotifierProvider.value(value: state, child: const RadarApp()));
}

class RadarApp extends StatelessWidget {
  const RadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = buildDarkTheme();
    final textScale = context.select<AppState, double>((s) => s.textScale);
    return MaterialApp(
      title: 'Radar Territorial',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      themeAnimationDuration: Duration.zero,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Tamanho do texto escolhido no app, somado ao ajuste do sistema.
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(media.textScaler.scale(1) * textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
