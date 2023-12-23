import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:flux_news_desktop/fluent_app_main_view.dart';
import 'package:flux_news_desktop/fluent_theme.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:system_date_time_format/system_date_time_format.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

Future<void> main() async {
  // Initialize FFI
  databaseFactory = databaseFactoryFfi;
  sqfliteFfiInit();

  WidgetsFlutterBinding.ensureInitialized();
  // if it's not on the web, windows or android, load the accent color
  SystemTheme.accentColor.load();
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

  runApp(const SDTFScope(child: FluxNewsDesktop()));
}

class FluxNewsDesktop extends StatelessWidget {
  const FluxNewsDesktop({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => FluxNewsState(),
        builder: (context, child) {
          return ChangeNotifierProvider(
              create: (context) => FluxNewsCounterState(),
              builder: (context, child) {
                return ChangeNotifierProvider(
                    create: (context) => FluentAppTheme(),
                    builder: (context, child) {
                      final appTheme = context.watch<FluentAppTheme>();

                      return FluentApp(
                        title: FluxNewsState.applicationName,
                        themeMode: appTheme.mode,
                        debugShowCheckedModeBanner: false,
                        color: appTheme.color,
                        darkTheme: FluentThemeData(
                          brightness: Brightness.dark,
                          accentColor: appTheme.color,
                          visualDensity: VisualDensity.standard,
                          focusTheme: FocusThemeData(
                            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
                          ),
                        ),
                        theme: FluentThemeData(
                          accentColor: appTheme.color,
                          visualDensity: VisualDensity.standard,
                          focusTheme: FocusThemeData(
                            glowFactor: is10footScreen(context) ? 2.0 : 0.0,
                          ),
                        ),
                        localizationsDelegates:
                            AppLocalizations.localizationsDelegates,
                        supportedLocales: const [
                          Locale('en', ''),
                          Locale('de', ''),
                        ],
                        home: const FluentNavigationMainView(),
                      );
                    });
              });
        });
  }
}
