import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database/database_backend.dart';
import 'package:flux_news_desktop/state/flux_news_counter_state.dart';
import 'package:flux_news_desktop/state/flux_news_state.dart';
import 'package:flux_news_desktop/functions/logging.dart';
import 'package:flux_news_desktop/miniflux_backend/miniflux_backend.dart';
import 'package:flux_news_desktop/models/news_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:my_logger/core/constants.dart';

Future<void> markAsBookmarkContextFunction(
    News news, FluxNewsState appState, BuildContext context, bool searchView) async {
  // switch between bookmarked or not bookmarked depending on the previous status
  if (news.starred) {
    news.starred = false;
  } else {
    news.starred = true;
  }

  // toggle the news as bookmarked or not bookmarked at the miniflux server
  await toggleBookmark(http.Client(), appState, news).onError((error, stackTrace) {
    logThis('toggleBookmark', 'Caught an error in toggleBookmark function! : ${error.toString()}', LogLevel.ERROR,
        stackTrace: stackTrace);
    if (context.mounted) {
      if (appState.errorString != AppLocalizations.of(context)!.communicateionMinifluxError) {
        appState.errorString = AppLocalizations.of(context)!.communicateionMinifluxError;
        appState.newError = true;
        appState.refreshView();
      }
    }
  });

  // update the bookmarked status in the database
  try {
    updateNewsStarredStatusInDB(news.newsID, news.starred, appState);
    if (context.mounted) {
      updateStarredCounter(appState, context);
    }
  } on Exception catch (exception, stackTrace) {
    logThis('updateNewsStarredStatusInDB', 'Caught an error in updateNewsStarredStatusInDB function!', LogLevel.ERROR,
        exception: exception, stackTrace: stackTrace);

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
      appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
        appState.jumpToItem(0);
      });
      appState.refreshView();
    } else {
      if (searchView) {
        // update the news list of the main view
        appState.newsList = queryNewsFromDB(appState, appState.feedIDs).onError((error, stackTrace) {
          logThis(
              'queryNewsFromDB', 'Caught an error in queryNewsFromDB function! : ${error.toString()}', LogLevel.ERROR,
              stackTrace: stackTrace);
          if (context.mounted) {
            appState.errorString = AppLocalizations.of(context)!.databaseError;
          }
          return [];
        });
      }
      appState.refreshView();
    }
  }
}

void markNewsAsReadContextAction(
    News news, FluxNewsState appState, BuildContext context, bool searchView, FluxNewsCounterState appCounterState) {
  // mark a news as unread, update the news unread status in database
  try {
    updateNewsStatusInDB(news.newsID, FluxNewsState.unreadNewsStatus, appState);
  } on Exception catch (exception, stackTrace) {
    logThis('updateNewsStatusInDB', 'Caught an error in updateNewsStatusInDB function!', LogLevel.ERROR,
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
      logThis('toggleOneNewsAsRead', 'Caught an error in toggleOneNewsAsRead function!', LogLevel.ERROR,
          exception: exception, stackTrace: stackTrace);
    }
    // update the news list of the main view
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).onError((error, stackTrace) {
      logThis('queryNewsFromDB', 'Caught an error in queryNewsFromDB function! : ${error.toString()}', LogLevel.ERROR,
          stackTrace: stackTrace);
      if (context.mounted) {
        appState.errorString = AppLocalizations.of(context)!.databaseError;
      }
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
    News news, FluxNewsState appState, BuildContext context, bool searchView, FluxNewsCounterState appCounterState) {
  // mark a news as read, update the news read status in database
  try {
    updateNewsStatusInDB(news.newsID, FluxNewsState.readNewsStatus, appState);
  } on Exception catch (exception, stackTrace) {
    logThis('updateNewsStatusInDB', 'Caught an error in updateNewsStatusInDB function!', LogLevel.ERROR,
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
      logThis('toggleOneNewsAsRead', 'Caught an error in toggleOneNewsAsRead function!}', LogLevel.ERROR,
          exception: exception, stackTrace: stackTrace);
    }
    // update the news list of the main view
    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).onError((error, stackTrace) {
      logThis('queryNewsFromDB', 'Caught an error in queryNewsFromDB function! : ${error.toString()}', LogLevel.ERROR,
          stackTrace: stackTrace);
      if (context.mounted) {
        appState.errorString = AppLocalizations.of(context)!.databaseError;
      }
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

Future<void> saveNewsInThirdPartyContextAction(News news, FluxNewsState appState, BuildContext context) async {
  await saveNewsToThirdPartyService(http.Client(), appState, news).onError((error, stackTrace) {
    logThis('saveNewsToThirdPartyService',
        'Caught an error in saveNewsToThirdPartyService function! : ${error.toString()}', LogLevel.ERROR);

    if (!appState.newError) {
      if (context.mounted) {
        appState.errorString = AppLocalizations.of(context)!.communicateionMinifluxError;
      }
      appState.newError = true;
      appState.refreshView();
    }
  });
  if (context.mounted) {
    await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(AppLocalizations.of(context)!.successfullSaveToThirdParty),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: InfoBarSeverity.info,
      );
    });
  }
}
