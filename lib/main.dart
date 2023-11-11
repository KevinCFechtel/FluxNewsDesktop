import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

/// Checks if the current environment is a desktop environment.
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

Future<void> main() async {
  // Initialize FFI
  sqfliteFfiInit();
  WidgetsFlutterBinding.ensureInitialized();

  // if it's not on the web, windows or android, load the accent color
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await flutter_acrylic.Window.hideWindowControls();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.normal,
        windowButtonVisibility: true,
      );
      await windowManager.setMinimumSize(const Size(500, 600));
      await windowManager.show();
      await windowManager.setPreventClose(false);
      await windowManager.setSkipTaskbar(false);
      windowManager.setTitle(FluxNewsState.applicationName);
    });
  }

  runApp(const FluxNewsDesktop());
}

class FluxNewsDesktop extends StatelessWidget {
  const FluxNewsDesktop({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FluxNewsState(),
      builder: (context, child) {
        return FluentApp(
          title: FluxNewsState.applicationName,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          color: Colors.blue,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: Colors.blue,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: Colors.blue,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: const [
            Locale('en', ''),
            Locale('de', ''),
          ],
          home: NavigationView(
            appBar: const NavigationAppBar(
              title: Text(FluxNewsState.applicationName),
            ),
            pane: NavigationPane(displayMode: PaneDisplayMode.auto, items: [
              PaneItem(
                  icon: const Icon(FluentIcons.home),
                  title: const Text("Home"),
                  body: const SizedBox.shrink()),
              PaneItem(
                  icon: const Icon(FluentIcons.insert),
                  title: const Text("Insert"),
                  body: const SizedBox.shrink()),
              PaneItem(
                  icon: const Icon(FluentIcons.view),
                  title: const Text("View"),
                  body: const SizedBox.shrink())
            ]),
          ),
        );
      },
    );
  }
}
