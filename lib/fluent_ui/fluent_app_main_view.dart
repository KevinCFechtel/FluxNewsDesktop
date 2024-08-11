import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database/database_backend.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_main_news_list.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_theme.dart';
import 'package:flux_news_desktop/state/flux_news_counter_state.dart';
import 'package:flux_news_desktop/state/flux_news_state.dart';
import 'package:flux_news_desktop/functions/logging.dart';
import 'package:flux_news_desktop/models/news_model.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_search.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_settings.dart';
import 'package:flux_news_desktop/functions/sync_news.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:my_logger/core/constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:system_date_time_format/system_date_time_format.dart';

class FluentNavigationMainView extends StatelessWidget {
  const FluentNavigationMainView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();
    return FluxNewsBodyStatefulWrapper(
      onInit: () {
        initConfig(context, appState, appTheme);
        appState.categoryList = queryCategoriesFromDB(appState, context);
        appState.newsList = Future<List<News>>.value([]);
      },
      child: const FluentCategorieNavigationMainView(),
    );
  }

  // helper function for the initState() to use async function on init
  Future<void> initConfig(BuildContext context, FluxNewsState appState, FluentAppTheme appTheme) async {
    await appState.initLogging();
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

        if (appState.brightnessMode == FluxNewsState.brightnessModeDarkString) {
          appTheme.mode = ThemeMode.dark;
        } else if (appState.brightnessMode == FluxNewsState.brightnessModeLightString) {
          appTheme.mode = ThemeMode.light;
        } else {
          appTheme.mode = ThemeMode.system;
        }
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
        } on Exception catch (exception, stacktrace) {
          logThis('initConfig', 'Caught an error in initConfig function!', LogLevel.ERROR,
              exception: exception, stackTrace: stacktrace);

          if (context.mounted) {
            if (appState.errorString != AppLocalizations.of(context)!.databaseError) {
              appState.errorString = AppLocalizations.of(context)!.databaseError;
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

      if (appState.minifluxURL == null || appState.minifluxAPIKey == null || appState.errorOnMinifluxAuth) {
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

class FluentCategorieNavigationMainView extends StatelessWidget {
  const FluentCategorieNavigationMainView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // read the date format of the system and assign it to the date format variable
    final mediumDatePattern = SystemDateTimeFormat.of(context).mediumDatePattern;
    final timePattern = SystemDateTimeFormat.of(context).timePattern;
    final dateFormatString = '$mediumDatePattern $timePattern';

    FluxNewsState appState = context.watch<FluxNewsState>();
    FluxNewsCounterState appCounterState = context.watch<FluxNewsCounterState>();
    appState.dateFormat = DateFormat(dateFormatString);
    double width = MediaQuery.of(context).size.width;

    var getData = FutureBuilder<Categories>(
        future: appState.categoryList,
        builder: (context, snapshot) {
          PaneItem homeListTile = PaneItem(
            icon: const Icon(
              FluentIcons.home,
            ),
            title: Text(
              AppLocalizations.of(context)!.allNews,
            ),
            infoBadge: InfoBadge(
              source: Padding(
                padding: const EdgeInsets.fromLTRB(10, 1, 10, 0),
                child: Text(
                  '${appCounterState.allNewsCount}',
                ),
              ),
            ),
            body: const FluentMainView(),
            onTap: () {
              appState.selectedNavigation = FluxNewsState.rootRouteString;
              appState.refreshView();
              allNewsOnClick(appState, context);
            },
          );
          PaneItem bookmarkedListtile = PaneItem(
            icon: const Icon(
              FluentIcons.favorite_star_fill,
            ),
            title: Text(
              AppLocalizations.of(context)!.bookmarked,
            ),
            infoBadge: InfoBadge(
              source: Padding(
                padding: const EdgeInsets.fromLTRB(10, 1, 10, 0),
                child: Text(
                  '${appCounterState.starredCount}',
                ),
              ),
            ),
            body: const FluentMainView(),
            onTap: () {
              appState.selectedNavigation = FluxNewsState.bookmarkedRouteString;
              appState.refreshView();
              bookmarkedOnClick(appState, context);
            },
          );
          NavigationView navPane = NavigationView(
            appBar: const NavigationAppBar(
              leading: Icon(FontAwesomeIcons.bookOpen),
              title: AppBarTitle(),
              actions: AppBarButtons(),
            ),
            transitionBuilder: (child, animation) {
              return SuppressPageTransition(
                child: child,
              );
            },
            pane: NavigationPane(
                header: const NavigationHeader(),
                displayMode: width >= 2000 ? PaneDisplayMode.open : PaneDisplayMode.minimal,
                selected: appState.calculateSelectedFluentNavigationItem(),
                items: [
                  homeListTile,
                  bookmarkedListtile
                ],
                footerItems: [
                  PaneItem(
                    icon: const Icon(FluentIcons.search),
                    title: Text(AppLocalizations.of(context)!.search),
                    body: const FluentSearch(),
                    onTap: () {
                      appState.selectedNavigation = FluxNewsState.searchRouteString;
                      appState.refreshView();
                    },
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.settings),
                    title: Text(AppLocalizations.of(context)!.settings),
                    body: const FluentSettings(),
                    onTap: () {
                      appState.selectedNavigation = FluxNewsState.settingsRouteString;
                      appState.refreshView();
                    },
                  )
                ]),
          );
          if (appCounterState.listUpdated) {
            appCounterState.listUpdated = false;
            snapshot.data?.renewNewsCount(appState, context);
            renewAllNewsCount(appState, context);
          }
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            default:
              if (!snapshot.hasError) {
                if (snapshot.data != null) {
                  if (snapshot.data!.categories.isNotEmpty) {
                    List<NavigationPaneItem> items = [];
                    items.add(homeListTile);
                    for (Category category in snapshot.data!.categories) {
                      String routeString = "/Categoriy/${category.categoryID}";
                      if (items.length > 2) {
                        items.add(PaneItemSeparator());
                      }
                      List<NavigationPaneItem> feedItems = [];
                      for (Feed feed in category.feeds) {
                        String routeString = "/Feed/${feed.feedID}";
                        feedItems.add(PaneItem(
                          icon: appState.showFeedIcons ? feed.getFeedIcon(16.0, context) : const SizedBox.shrink(),
                          title: Text(
                            feed.title,
                          ),
                          infoBadge: InfoBadge(
                            source: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 1, 10, 0),
                              child: Text(
                                '${feed.newsCount}',
                              ),
                            ),
                          ),
                          trailing: appState.truncateMode == 2
                              ? ToggleButton(
                                  checked: feed.manualTruncate != null ? feed.manualTruncate! : false,
                                  onChanged: (value) async {
                                    feed.manualTruncate = value;
                                    await updateManualTruncateStatusOfFeedInDB(feed.feedID, value, appState);
                                    appState.refreshView();
                                  },
                                  child: const Icon(FluentIcons.cut),
                                )
                              : const SizedBox.shrink(),
                          body: const FluentMainView(),
                          onTap: () {
                            appState.selectedNavigation = routeString;
                            appState.refreshView();
                            feedOnClick(feed, appState, snapshot.data!, context);
                          },
                        ));
                      }
                      items.add(PaneItemExpander(
                        icon: const Icon(FluentIcons.category_classification),
                        title: Text(
                          category.title,
                        ),
                        infoBadge: InfoBadge(
                          source: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 1, 10, 0),
                            child: Text(
                              '${category.newsCount}',
                            ),
                          ),
                        ),
                        trailing: const Icon(FluentIcons.chevron_up),
                        items: feedItems,
                        body: const FluentMainView(),
                        onTap: () {
                          appState.selectedNavigation = routeString;
                          appState.refreshView();
                          categoryOnClick(category, appState, snapshot.data!, context);
                        },
                      ));
                      /*
                      items.add(PaneItem(
                        icon: const Icon(FluentIcons.category_classification),
                        title: Text(
                          category.title,
                        ),
                        infoBadge: InfoBadge(
                          source: Text(
                            '${category.newsCount}',
                          ),
                        ),
                        body: const FluentMainView(),
                        onTap: () {
                          appState.selectedNavigation = routeString;
                          appState.refreshView();
                          categoryOnClick(
                              category, appState, snapshot.data!, context);
                        },
                      ));*/
                    }
                    items.add(bookmarkedListtile);
                    navPane = NavigationView(
                      appBar: const NavigationAppBar(
                        leading: Icon(FontAwesomeIcons.bookOpen),
                        title: AppBarTitle(),
                        actions: Center(child: AppBarButtons()),
                      ),
                      transitionBuilder: (child, animation) {
                        return SuppressPageTransition(
                          child: child,
                        );
                      },
                      pane: NavigationPane(
                          header: const NavigationHeader(),
                          displayMode: width >= 2000 ? PaneDisplayMode.open : PaneDisplayMode.minimal,
                          selected: appState.calculateSelectedFluentNavigationItem(),
                          items: items,
                          footerItems: [
                            PaneItem(
                              icon: const Icon(FluentIcons.search),
                              title: Text(AppLocalizations.of(context)!.search),
                              body: const FluentSearch(),
                              onTap: () {
                                appState.selectedNavigation = FluxNewsState.searchRouteString;
                                appState.refreshView();
                              },
                            ),
                            PaneItem(
                              icon: const Icon(FluentIcons.settings),
                              title: Text(AppLocalizations.of(context)!.settings),
                              body: const FluentSettings(),
                              onTap: () {
                                appState.selectedNavigation = FluxNewsState.settingsRouteString;
                                appState.refreshView();
                              },
                            )
                          ]),
                    );
                  }
                }
              }
          }
          return navPane;
        });
    return getData;
  }

  Future<void> feedOnClick(Feed feed, FluxNewsState appState, Categories categories, BuildContext context) async {
    appState.selectedCategoryElementType = FluxNewsState.feedElementType;
    // on tab we want to show only the news of this feed in the news list.
    // set the feed id of the selected feed in the feedIDs filter
    appState.feedIDs = [feed.feedID];
    // reload the news list with the new filter
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
      waitUntilNewsListBuild(appState).whenComplete(
        () {
          appState.itemScrollController.jumpTo(index: 0);
        },
      );
    });
    // set the feed title as app bar title
    // and update the news count in the app bar, if the function is activated.
    appState.appBarText = feed.title;
    categories.renewNewsCount(appState, context);
    // update the view after changing the values
    appState.refreshView();
  }

  // if the title of the category is clicked,
  // we want all the news of this category in the news view.
  Future<void> categoryOnClick(
      Category category, FluxNewsState appState, Categories categories, BuildContext context) async {
    appState.selectedCategoryElementType = FluxNewsState.categoryElementType;
    // add the according feeds of this category as a filter
    appState.feedIDs = category.getFeedIDs();
    // reload the news list with the new filter
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
      waitUntilNewsListBuild(appState).whenComplete(
        () {
          appState.itemScrollController.jumpTo(index: 0);
        },
      );
    });
    // set the category title as app bar title
    // and update the news count in the app bar, if the function is activated.
    appState.appBarText = category.title;
    categories.renewNewsCount(appState, context);
    // update the view after changing the values
    appState.refreshView();
  }

  // if the "All News" ListTile is clicked,
  // we want all the news in the news view.
  Future<void> allNewsOnClick(FluxNewsState appState, BuildContext context) async {
    appState.selectedCategoryElementType = FluxNewsState.allNewsElementType;
    // empty the feedIds which are used as a filter if a specific category is selected
    appState.feedIDs = null;
    // reload the news list with the new filter (empty)
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
      waitUntilNewsListBuild(appState).whenComplete(
        () {
          appState.itemScrollController.jumpTo(index: 0);
        },
      );
    });
    // set the "All News" title as app bar title
    // and update the news count in the app bar, if the function is activated.
    appState.appBarText = AppLocalizations.of(context)!.allNews;
    if (context.mounted) {
      renewAllNewsCount(appState, context);
    }
    // update the view after changing the values
    appState.refreshView();
  }

  // if the "Bookmarked" ListTile is clicked,
  // we want all the bookmarked news in the news view.
  Future<void> bookmarkedOnClick(FluxNewsState appState, BuildContext context) async {
    appState.selectedCategoryElementType = FluxNewsState.bookmarkedNewsElementType;
    // set the feedIDs filter to -1 to only load bookmarked news
    // -1 is a impossible feed id of a regular miniflux feed,
    // so we use it to decide between all news (feedIds = null)
    // and bookmarked news (feedIds = -1).
    appState.feedIDs = [-1];
    // reload the news list with the new filter (-1 only bookmarked news)
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
      waitUntilNewsListBuild(appState).whenComplete(
        () {
          appState.itemScrollController.jumpTo(index: 0);
        },
      );
    });
    // set the "Bookmarked" title as app bar title
    // and update the news count in the app bar, if the function is activated.
    appState.appBarText = AppLocalizations.of(context)!.bookmarked;
    if (context.mounted) {
      updateStarredCounter(appState, context);
    }
    // update the view after changing the values
    appState.refreshView();
  }
}

class NavigationHeader extends StatelessWidget {
  const NavigationHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    return Column(
      children: [
        ListTile(
          title: Text(
            AppLocalizations.of(context)!.minifluxServer,
          ),
          subtitle: appState.minifluxURL == null ? const SizedBox.shrink() : Text(appState.minifluxURL!),
        ),
      ],
    );
  }
}

class AppBarButtons extends StatelessWidget {
  const AppBarButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluxNewsCounterState appCounterState = context.watch<FluxNewsCounterState>();

    return CommandBar(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      secondaryItems: [
        CommandBarButton(
          onPressed: () async {
            // switch between all and only unread news view
            // if the current view is unread news change to all news
            if (appState.newsStatus == FluxNewsState.unreadNewsStatus) {
              // switch the state to all news
              appState.newsStatus = FluxNewsState.allNewsString;

              // save the state persistent
              appState.storage.write(key: FluxNewsState.secureStorageNewsStatusKey, value: FluxNewsState.allNewsString);

              // refresh news list with the all news state
              appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                waitUntilNewsListBuild(appState).whenComplete(
                  () {
                    context.read<FluxNewsState>().itemScrollController.jumpTo(index: 0);
                  },
                );
              });

              // notify the categories to update the news count
              appCounterState.listUpdated = true;
              appCounterState.refreshView();
              appState.refreshView();
              // if the current view is all news change to only unread news
            } else {
              // switch the state to show only unread news
              appState.newsStatus = FluxNewsState.unreadNewsStatus;

              // save the state persistent
              appState.storage
                  .write(key: FluxNewsState.secureStorageNewsStatusKey, value: FluxNewsState.unreadNewsStatus);

              // refresh news list with the only unread news state
              appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                waitUntilNewsListBuild(appState).whenComplete(
                  () {
                    context.read<FluxNewsState>().itemScrollController.jumpTo(index: 0);
                  },
                );
              });

              // notify the categories to update the news count
              appCounterState.listUpdated = true;
              appCounterState.refreshView();
              appState.refreshView();
            }
            Navigator.pop(context);
          },
          label: Text(AppLocalizations.of(context)!.newsReadFilter),
          icon: appState.newsStatus == FluxNewsState.unreadNewsStatus
              ? const SizedBox(
                  height: 25.0,
                  width: 25.0,
                  child: Center(child: Text("New", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))))
              : const Padding(
                  padding: EdgeInsets.only(
                    left: 5.0,
                  ),
                  child: Icon(FluentIcons.accept, size: 20.0),
                ),
        ),
        CommandBarButton(
          onPressed: () async {
            // switch between newest first and oldest first
            // if the current sort order is newest first change to oldest first
            if (appState.sortOrder == FluxNewsState.sortOrderNewestFirstString) {
              // switch the state to all news
              appState.sortOrder = FluxNewsState.sortOrderOldestFirstString;

              // save the state persistent
              await appState.storage
                  .write(key: FluxNewsState.secureStorageSortOrderKey, value: FluxNewsState.sortOrderOldestFirstString);

              // refresh news list with the all news state
              appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                waitUntilNewsListBuild(appState).whenComplete(
                  () {
                    context.read<FluxNewsState>().itemScrollController.jumpTo(index: 0);
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
              await appState.storage
                  .write(key: FluxNewsState.secureStorageSortOrderKey, value: FluxNewsState.sortOrderNewestFirstString);

              // refresh news list with the only unread news state
              appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                waitUntilNewsListBuild(appState).whenComplete(
                  () {
                    context.read<FluxNewsState>().itemScrollController.jumpTo(index: 0);
                  },
                );
              });

              // notify the categories to update the news count
              appCounterState.listUpdated = true;
              appCounterState.refreshView();
              appState.refreshView();
            }
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          label: Text(AppLocalizations.of(context)!.sortOrderOfNews),
          icon: appState.sortOrder == FluxNewsState.sortOrderNewestFirstString
              ? const Icon(FluentIcons.sort_lines, size: 20.0)
              : const Icon(FluentIcons.sort_lines_ascending, size: 20.0),
        ),
        CommandBarButton(
          onPressed: () {
            // mark news as read
            markNewsAsReadInDB(appState);
            // refresh news list with the all news state
            appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
              waitUntilNewsListBuild(appState).whenComplete(
                () {
                  context.read<FluxNewsState>().itemScrollController.jumpTo(index: 0);
                },
              );
            });

            // notify the categories to update the news count
            appCounterState.listUpdated = true;
            appCounterState.refreshView();
            appState.refreshView();
            Navigator.pop(context);
          },
          label: appState.selectedCategoryElementType == FluxNewsState.feedElementType
              ? Text(AppLocalizations.of(context)!.markFeedAsRead)
              : appState.selectedCategoryElementType == FluxNewsState.categoryElementType
                  ? Text(AppLocalizations.of(context)!.markCategoryAsRead)
                  : appState.selectedCategoryElementType == FluxNewsState.bookmarkedNewsElementType
                      ? Text(AppLocalizations.of(context)!.markBookmarkedAsRead)
                      : Text(AppLocalizations.of(context)!.markAllAsRead),
          icon: const SizedBox(
            height: 20.0,
            width: 20.0,
            child: Icon(FluentIcons.check_list),
          ),
        ),
      ],
      primaryItems: [
        CommandBarButton(
          onPressed: () async {
            await syncNews(appState, context);
          },
          label: width > 1600 ? Text(AppLocalizations.of(context)!.sync) : const SizedBox.shrink(),
          icon: appState.syncProcess
              ? const SizedBox(
                  height: 15.0,
                  width: 15.0,
                  child: ProgressRing(),
                )
              : const Icon(FluentIcons.refresh, size: 15.0),
        ),
      ],
    );
  }
}

class AppBarTitle extends StatelessWidget {
  const AppBarTitle({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluxNewsCounterState appCounterState = context.watch<FluxNewsCounterState>();
    FluxNewsState appState = context.watch<FluxNewsState>();
    double width = MediaQuery.of(context).size.width;

    // set the app bar title depending on the chosen category to show in list view

    if (appState.multilineAppBarText && width > 1300) {
      // this is the part where the news count is added as an extra line to the app bar title
      return Builder(builder: (BuildContext context) {
        return Text(
            "${appState.appBarText} - ${AppLocalizations.of(context)!.itemCount}: ${appCounterState.appBarNewsCount}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ));
      });
    } else {
      // this is the part without the news count as an extra line
      return Text(appState.appBarText,
          textAlign: TextAlign.start,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ));
    }
  }
}

class FluentMainView extends StatelessWidget {
  const FluentMainView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return const FluentBodyNewsList();
  }
}

class FluxNewsBodyStatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const FluxNewsBodyStatefulWrapper({super.key, required this.onInit, required this.child});
  @override
  FluxNewsBodyState createState() => FluxNewsBodyState();
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
