import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database_backend.dart';
import 'package:flux_news_desktop/fluent_news_card.dart';
import 'package:flux_news_desktop/fluent_news_row.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:flux_news_desktop/logging.dart';
import 'package:flux_news_desktop/news_model.dart';
import 'package:my_logger/core/constants.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

// the list view widget with news (main view)
class FluentBodyNewsList extends StatelessWidget {
  const FluentBodyNewsList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    FluxNewsState appState = context.watch<FluxNewsState>();
    bool searchView = false;
    logThis("NewsList", "Rebuild", LogLevel.INFO);
    var getData = FutureBuilder<List<News>>(
      future: appState.newsList,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.waiting:
          default:
            if (snapshot.hasError) {
              return const SizedBox.shrink();
            } else {
              return snapshot.data == null
                  // show empty dialog if list is null
                  ? Center(
                      child: Text(
                      AppLocalizations.of(context)!.noNewEntries,
                    ))
                  // show empty dialog if list is empty
                  : snapshot.data!.isEmpty
                      ? Center(
                          child: Text(
                          AppLocalizations.of(context)!.noNewEntries,
                        ))
                      // otherwise create list view with ScrollablePositionedList
                      // to save scroll position persistent
                      : Stack(children: [
                          NotificationListener<ScrollEndNotification>(
                            child: ScrollablePositionedList.builder(
                                key: const PageStorageKey<String>('NewsList'),
                                itemCount: snapshot.data!.length,
                                itemScrollController:
                                    appState.itemScrollController,
                                itemPositionsListener:
                                    appState.itemPositionsListener,
                                initialScrollIndex: appState.scrollPosition,
                                itemBuilder: (context, i) {
                                  return width <= 1600
                                      ? FluentNewsCard(
                                          news: snapshot.data![i],
                                          context: context,
                                          searchView: searchView)
                                      : FluentNewsRow(
                                          news: snapshot.data![i],
                                          context: context,
                                          searchView: searchView);
                                }),
                            // on ScrollNotification set news as read on scroll over if activated
                            onNotification: (ScrollNotification scrollInfo) {
                              final metrics = scrollInfo.metrics;
                              // check if set read on scroll over is activated in settings
                              if (context
                                  .read<FluxNewsState>()
                                  .markAsReadOnScrollOver) {
                                // if the sync is in progress, no news should marked as read
                                if (appState.syncProcess == false) {
                                  // set all news as read if the list reached the bottom (the edge)
                                  if (metrics.atEdge) {
                                    // to ensure that the list is at the bottom edge and not at the top edge
                                    // the amount of scrolled pixels must be greater 0
                                    if (metrics.pixels > 0) {
                                      // iterate through the whole news list and mark news as read
                                      for (int i = 0;
                                          i < snapshot.data!.length;
                                          i++) {
                                        try {
                                          updateNewsStatusInDB(
                                              snapshot.data![i].newsID,
                                              FluxNewsState.readNewsStatus,
                                              appState);
                                        } on Exception catch (exception, stacktrace) {
                                          logThis(
                                              'updateNewsStatusInDB',
                                              'Caught an error in updateNewsStatusInDB function!',
                                              LogLevel.ERROR,
                                              exception: exception,
                                              stackTrace: stacktrace);

                                          if (context
                                                  .read<FluxNewsState>()
                                                  .errorString !=
                                              AppLocalizations.of(context)!
                                                  .databaseError) {
                                            context
                                                    .read<FluxNewsState>()
                                                    .errorString =
                                                AppLocalizations.of(context)!
                                                    .databaseError;
                                            context
                                                .read<FluxNewsState>()
                                                .newError = true;
                                            context
                                                .read<FluxNewsState>()
                                                .refreshView();
                                          }
                                        }
                                        snapshot.data![i].status =
                                            FluxNewsState.readNewsStatus;
                                      }
                                      // set the scroll position back to the top of the list
                                      context
                                          .read<FluxNewsState>()
                                          .scrollPosition = 0;
                                    }
                                  } else {
                                    // if the list doesn't reached the bottom,
                                    // mark the news which got scrolled over as read.
                                    // Iterate through the news list from start
                                    // to the actual position and mark them as read
                                    for (int i = 0;
                                        i <
                                            context
                                                .read<FluxNewsState>()
                                                .scrollPosition;
                                        i++) {
                                      try {
                                        updateNewsStatusInDB(
                                            snapshot.data![i].newsID,
                                            FluxNewsState.readNewsStatus,
                                            appState);
                                      } on Exception catch (exception, stacktrace) {
                                        logThis(
                                            'updateNewsStatusInDB',
                                            'Caught an error in updateNewsStatusInDB function!',
                                            LogLevel.ERROR,
                                            exception: exception,
                                            stackTrace: stacktrace);

                                        if (context
                                                .read<FluxNewsState>()
                                                .errorString !=
                                            AppLocalizations.of(context)!
                                                .databaseError) {
                                          context
                                                  .read<FluxNewsState>()
                                                  .errorString =
                                              AppLocalizations.of(context)!
                                                  .databaseError;
                                          context
                                              .read<FluxNewsState>()
                                              .newError = true;
                                          context
                                              .read<FluxNewsState>()
                                              .refreshView();
                                        }
                                      }
                                      snapshot.data![i].status =
                                          FluxNewsState.readNewsStatus;
                                    }
                                  }
                                }
                                // mark the list as updated to recalculate the news count
                                context
                                    .read<FluxNewsCounterState>()
                                    .listUpdated = true;
                                appState.refreshView();
                                context
                                    .read<FluxNewsCounterState>()
                                    .refreshView();
                              }
                              // return always false to ensure the processing of the notification
                              return false;
                            },
                          ),
                          // get the actual scroll position on stop scrolling
                          positionsView(context, appState),
                        ]);
            }
        }
      },
    );
    return getData;
  }
}

// here is a helper function to get the first visible widget in the list view
// this widget is used as the limit on marking previous news as read.
// so every item of the list, which is previous to the first visible
// will be marked as read.
Widget positionsView(BuildContext context, FluxNewsState appState) =>
    ValueListenableBuilder<Iterable<ItemPosition>>(
      valueListenable: appState.itemPositionsListener.itemPositions,
      builder: (context, positions, child) {
        int? firstItem;
        if (positions.isNotEmpty) {
          firstItem = positions
              .where((ItemPosition position) => position.itemTrailingEdge > 0)
              .reduce((ItemPosition first, ItemPosition position) =>
                  position.itemTrailingEdge < first.itemTrailingEdge
                      ? position
                      : first)
              .index;
        }
        if (firstItem == null) {
          appState.scrollPosition = 0;
          appState.storage.write(
              key: FluxNewsState.secureStorageSavedScrollPositionKey,
              value: '0');
        } else {
          appState.scrollPosition = firstItem;
          appState.storage.write(
              key: FluxNewsState.secureStorageSavedScrollPositionKey,
              value: firstItem.toString());
        }
        return const SizedBox.shrink();
      },
    );
