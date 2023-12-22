import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_news_desktop/database_backend.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:flux_news_desktop/logging.dart';
import 'package:flux_news_desktop/news_model.dart';
import 'package:flux_news_desktop/sync_news.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:provider/provider.dart';

class MacNavigationMainView extends StatelessWidget {
  const MacNavigationMainView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    return FluxNewsBodyStatefulWrapper(
      onInit: () {
        initConfig(context, appState);
        appState.categoryList = queryCategoriesFromDB(appState, context);
        appState.newsList = Future<List<News>>.value([]);
      },
      child: const MacCategorieNavigationMainView(),
    );
  }

  // helper function for the initState() to use async function on init
  Future<void> initConfig(BuildContext context, FluxNewsState appState) async {
    // read persistent saved config
    bool completed = await appState.readConfigValues();

    // init the sqlite database in startup
    appState.db = await appState.initializeDB();

    if (completed) {
      if (context.mounted) {
        // set the app bar text to "All News"
        appState.appBarText = AppLocalizations.of(context)!.allNews;
        // read the saved config
        appState.readConfig(context);
      }

      if (appState.syncOnStart) {
        // sync on startup
        if (context.mounted) {
          await syncNews(appState, context);
        }
      } else {
        // normal startup, read existing news from database and generate list view
        try {
          appState.newsList = queryNewsFromDB(appState, null);
          if (context.mounted) {
            updateStarredCounter(appState, context);
            await renewAllNewsCount(appState, context);
          }
        } catch (e) {
          logThis('initConfig', 'Caught an error in initConfig function!',
              Level.error);

          if (context.mounted) {
            if (appState.errorString !=
                AppLocalizations.of(context)!.databaseError) {
              appState.errorString =
                  AppLocalizations.of(context)!.databaseError;
              appState.newError = true;
              appState.refreshView();
            }
          }
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // set the scroll position to the persistent saved scroll position on normal startup
      // if sync on startup is enabled, the scroll position is set to the top of the list
      if (!appState.syncOnStart) {
        appState.scrollPosition = appState.savedScrollPosition;
      }

      if (appState.minifluxURL == null ||
          appState.minifluxAPIKey == null ||
          appState.errorOnMinifluxAuth) {
        // navigate to settings screen if there are problems with the miniflux config
        appState.refreshView();
        //Navigator.pushNamed(context, FluxNewsState.settingsRouteString);
      } else {
        // if everything is fine with the settings, present the list view
        appState.refreshView();
      }
    });
  }
}

class FluxNewsBodyStatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const FluxNewsBodyStatefulWrapper(
      {super.key, required this.onInit, required this.child});
  @override
  FluxNewsBodyState createState() => FluxNewsBodyState();
}

class MacCategorieNavigationMainView extends StatelessWidget {
  const MacCategorieNavigationMainView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    return MacosWindow(
      sidebar: Sidebar(
        minWidth: 200,
        builder: (context, scrollController) {
          return SidebarItems(
            currentIndex: appState.macNavigationPosition,
            scrollController: scrollController,
            itemSize: SidebarItemSize.large,
            onChanged: (value) {
              appState.macNavigationPosition = value;
              appState.refreshView();
            },
            items: const [
              SidebarItem(
                label: Text('Page One'),
              ),
              SidebarItem(
                label: Text('Page Two'),
              ),
            ],
          );
        },
      ),
      child: MacosScaffold(
        toolBar: getToolbar(context),
      ),
    );
  }

  ToolBar getToolbar(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluxNewsCounterState appCounterState =
        context.watch<FluxNewsCounterState>();
    return ToolBar(
      title: Text(appState.appBarText),
      titleWidth: 200.0,
      actions: [
        ToolBarIconButton(
          onPressed: () async {
            await syncNews(appState, context);
          },
          label: "",
          showLabel: false,
          icon: appState.syncProcess
              ? const SizedBox(
                  height: 15.0,
                  width: 15.0,
                  child: ProgressCircle(
                    value: null,
                  ),
                )
              : const MacosIcon(
                  CupertinoIcons.refresh,
                ),
        ),
        ToolBarIconButton(
          label: "",
          showLabel: false,
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
              ? const MacosIcon(CupertinoIcons.eye_fill)
              : const MacosIcon(CupertinoIcons.eye_slash),
        )
      ],
    );
  }
}

// extend class to save actual scroll state of the list view
class FluxNewsBodyState extends State<FluxNewsBodyStatefulWrapper> {
  // init the state of FluxNewsBody to load the config and the data on startup
  @override
  void initState() {
    widget.onInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
