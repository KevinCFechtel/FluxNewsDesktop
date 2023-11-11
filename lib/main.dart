import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:flux_news_desktop/database_backend.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:flux_news_desktop/search.dart';
import 'package:flux_news_desktop/sync_news.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
          return ChangeNotifierProvider(
            create: (context) => FluxNewsCounterState(),
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
                // define routes for main view (FluxNewsBody), settings view and search view
                routes: {
                  //FluxNewsState.rootRouteString: (context) =>
                  //    const FluxNewsBody(),
                  //FluxNewsState.settingsRouteString: (context) =>
                  //    const Settings(),
                  FluxNewsState.searchRouteString: (context) => const Search(),
                },
                home: const MainViewWidget(),
              );
            },
          );
        });
  }
}

class MainViewWidget extends StatelessWidget {
  const MainViewWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        leading: Icon(FontAwesomeIcons.bookOpen),
        title: Text(FluxNewsState.applicationName),
        actions: AppBarButtons(),
      ),
      pane: NavigationPane(displayMode: PaneDisplayMode.auto, items: [
        PaneItem(
            icon: const Icon(FluentIcons.boards),
            title: const Text("Home"),
            body: const SizedBox.shrink()),
        PaneItem(
          icon: const Icon(FluentIcons.search),
          title: Text(AppLocalizations.of(context)!.search),
          body: const SizedBox.shrink(),
          onTap: () {
            Navigator.pushNamed(context, FluxNewsState.searchRouteString);
          },
        ),
        PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            body: const SizedBox.shrink())
      ]),
      /*
      content: Center(
          child: Text(
        AppLocalizations.of(context)!.noNewEntries,
      )),
      */
    );
  }
}

class AppBarButtons extends StatelessWidget {
  const AppBarButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluxNewsCounterState appCounterState =
        context.watch<FluxNewsCounterState>();
    return Row(
      children: [
        IconButton(
          onPressed: () async {
            await syncNews(appState, context);
          },
          icon: appState.syncProcess
              ? const SizedBox(
                  height: 15.0,
                  width: 15.0,
                  //child: //CircularProgressIndicator.adaptive(),
                )
              : const Icon(
                  FluentIcons.refresh,
                ),
        ),
        IconButton(
          onPressed: () async {
            // switch between newest first and oldest first
            // if the current sort order is newest first change to oldest first
            if (appState.sortOrder ==
                FluxNewsState.sortOrderNewestFirstString) {
              // switch the state to all news
              appState.sortOrder = FluxNewsState.sortOrderOldestFirstString;

              // save the state persistent
              appState.storage.write(
                  key: FluxNewsState.secureStorageSortOrderKey,
                  value: FluxNewsState.sortOrderOldestFirstString);

              // refresh news list with the all news state
              appState.newsList =
                  queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                waitUntilNewsListBuild(appState).whenComplete(
                  () {
                    context
                        .read<FluxNewsState>()
                        .itemScrollController
                        .jumpTo(index: 0);
                  },
                );
              });

              // notify the categories to update the news count
              appCounterState.listUpdated = true;
              appCounterState.refreshView();
              appState.refreshView();
              // if the current sort order is oldest first change to newest first
            } else {
              // switch the state to show only unread news
              appState.sortOrder = FluxNewsState.sortOrderNewestFirstString;

              // save the state persistent
              appState.storage.write(
                  key: FluxNewsState.secureStorageSortOrderKey,
                  value: FluxNewsState.sortOrderNewestFirstString);

              // refresh news list with the only unread news state
              appState.newsList =
                  queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                waitUntilNewsListBuild(appState).whenComplete(
                  () {
                    context
                        .read<FluxNewsState>()
                        .itemScrollController
                        .jumpTo(index: 0);
                  },
                );
              });

              // notify the categories to update the news count
              appCounterState.listUpdated = true;
              appCounterState.refreshView();
              appState.refreshView();
            }
          },
          icon: appState.newsStatus == FluxNewsState.unreadNewsStatus
              ? const Icon(FluentIcons.read)
              : const Icon(FluentIcons.accept),
        )
      ],
    );
  }
}
