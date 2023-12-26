import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database_backend.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:flux_news_desktop/logging.dart';
import 'package:flux_news_desktop/miniflux_backend.dart';
import 'package:flux_news_desktop/news_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:my_logger/core/constants.dart';

Future<void> markAsBookmarkContextFunction(News news, FluxNewsState appState,
    BuildContext context, bool searchView) async {
  // switch between bookmarked or not bookmarked depending on the previous status
  if (news.starred) {
    news.starred = false;
  } else {
    news.starred = true;
  }

  // toggle the news as bookmarked or not bookmarked at the miniflux server
  await toggleBookmark(http.Client(), appState, news)
      .onError((error, stackTrace) {
    logThis(
        'toggleBookmark',
        'Caught an error in toggleBookmark function! : ${error.toString()}',
        LogLevel.ERROR,
        stackTrace: stackTrace);

    if (appState.errorString !=
        AppLocalizations.of(context)!.communicateionMinifluxError) {
      appState.errorString =
          AppLocalizations.of(context)!.communicateionMinifluxError;
      appState.newError = true;
      appState.refreshView();
    }
  });

  // update the bookmarked status in the database
  try {
    updateNewsStarredStatusInDB(news.newsID, news.starred, appState);
    if (context.mounted) {
      updateStarredCounter(appState, context);
    }
  } on Exception catch (exception, stackTrace) {
    logThis(
        'updateNewsStarredStatusInDB',
        'Caught an error in updateNewsStarredStatusInDB function!',
        LogLevel.ERROR,
        exception: exception,
        stackTrace: stackTrace);

    if (context.mounted) {
      if (appState.errorString != AppLocalizations.of(context)!.databaseError) {
        appState.errorString = AppLocalizations.of(context)!.databaseError;
        appState.newError = true;
        appState.refreshView();
      }
    }
  }

  // if we are in the bookmarked category, reload the list of bookmarked news
  // after the previous change, because there happened changes to this list.
  if (context.mounted) {
    if (appState.appBarText == AppLocalizations.of(context)!.bookmarked) {
      appState.feedIDs = [-1];
      appState.newsList =
          queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
        waitUntilNewsListBuild(appState).whenComplete(
          () {
            appState.itemScrollController.jumpTo(index: 0);
          },
        );
      });
      appState.refreshView();
    } else {
      if (searchView) {
        // update the news list of the main view
        appState.newsList = queryNewsFromDB(appState, appState.feedIDs)
            .onError((error, stackTrace) {
          logThis(
              'queryNewsFromDB',
              'Caught an error in queryNewsFromDB function! : ${error.toString()}',
              LogLevel.ERROR,
              stackTrace: stackTrace);

          appState.errorString = AppLocalizations.of(context)!.databaseError;
          return [];
        });
      }
      appState.refreshView();
    }
  }
}

void markNewsAsReadContextAction(
    News news,
    FluxNewsState appState,
    BuildContext context,
    bool searchView,
    FluxNewsCounterState appCounterState) {
  // mark a news as unread, update the news unread status in database
  try {
    updateNewsStatusInDB(news.newsID, FluxNewsState.unreadNewsStatus, appState);
  } on Exception catch (exception, stackTrace) {
    logThis('updateNewsStatusInDB',
        'Caught an error in updateNewsStatusInDB function!', LogLevel.ERROR,
        exception: exception, stackTrace: stackTrace);

    if (context.mounted) {
      if (appState.errorString != AppLocalizations.of(context)!.databaseError) {
        appState.errorString = AppLocalizations.of(context)!.databaseError;
        appState.newError = true;
        appState.refreshView();
      }
    }
  }
  // set the new unread status to the news object and toggle the recalculation
  // of the news counter
  news.status = FluxNewsState.unreadNewsStatus;
  if (searchView) {
    // update the news status at the miniflux server
    try {
      toggleOneNewsAsRead(http.Client(), appState, news);
    } on Exception catch (exception, stackTrace) {
      logThis('toggleOneNewsAsRead',
          'Caught an error in toggleOneNewsAsRead function!', LogLevel.ERROR,
          exception: exception, stackTrace: stackTrace);
    }
    // update the news list of the main view
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs)
        .onError((error, stackTrace) {
      logThis(
          'queryNewsFromDB',
          'Caught an error in queryNewsFromDB function! : ${error.toString()}',
          LogLevel.ERROR,
          stackTrace: stackTrace);

      appState.errorString = AppLocalizations.of(context)!.databaseError;
      return [];
    });
    appState.refreshView();
    appCounterState.listUpdated = true;
    appCounterState.refreshView();
  } else {
    appCounterState.listUpdated = true;
    appCounterState.refreshView();
    appState.refreshView();
  }
}

void markNewsAsUnreadContextAction(
    News news,
    FluxNewsState appState,
    BuildContext context,
    bool searchView,
    FluxNewsCounterState appCounterState) {
  // mark a news as read, update the news read status in database
  try {
    updateNewsStatusInDB(news.newsID, FluxNewsState.readNewsStatus, appState);
  } on Exception catch (exception, stackTrace) {
    logThis('updateNewsStatusInDB',
        'Caught an error in updateNewsStatusInDB function!', LogLevel.ERROR,
        exception: exception, stackTrace: stackTrace);

    if (context.mounted) {
      if (appState.errorString != AppLocalizations.of(context)!.databaseError) {
        appState.errorString = AppLocalizations.of(context)!.databaseError;
        appState.newError = true;
        appState.refreshView();
      }
    }
  }
  // set the new read status to the news object and toggle the recalculation
  // of the news counter
  news.status = FluxNewsState.readNewsStatus;

  if (searchView) {
    // update the news status at the miniflux server
    try {
      toggleOneNewsAsRead(http.Client(), appState, news);
    } on Exception catch (exception, stackTrace) {
      logThis('toggleOneNewsAsRead',
          'Caught an error in toggleOneNewsAsRead function!}', LogLevel.ERROR,
          exception: exception, stackTrace: stackTrace);
    }
    // update the news list of the main view
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs)
        .onError((error, stackTrace) {
      logThis(
          'queryNewsFromDB',
          'Caught an error in queryNewsFromDB function! : ${error.toString()}',
          LogLevel.ERROR,
          stackTrace: stackTrace);

      appState.errorString = AppLocalizations.of(context)!.databaseError;
      return [];
    });
    appState.refreshView();
    appCounterState.listUpdated = true;
    appCounterState.refreshView();
  } else {
    appCounterState.listUpdated = true;
    appCounterState.refreshView();
    appState.refreshView();
  }
}

// this function is needed because after the news are fetched from the database,
// the list of news need some time to be generated.
// only after the list is generated, we can set the scroll position of the list
// we can check that the list is generated if the scroll controller is attached to the list.
// so the function checks the scroll controller and if it's not attached it waits 1 millisecond
// and check then again if the scroll controller is attached.
// With calling this function as await, we can wait with the further processing
// on finishing with the list build.
Future<void> waitUntilNewsListBuild(FluxNewsState appState) async {
  final completer = Completer();
  if (appState.itemScrollController.isAttached) {
    await Future.delayed(const Duration(milliseconds: 1));
    return waitUntilNewsListBuild(appState);
  } else {
    completer.complete();
  }
  return completer.future;
}
