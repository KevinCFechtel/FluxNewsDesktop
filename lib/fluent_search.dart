import 'package:flutter/material.dart';
import 'package:flux_news_desktop/fluent_theme.dart';
import 'package:flux_news_desktop/logging.dart';
import 'package:flux_news_desktop/fluent_search_news_list.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

import 'flux_news_state.dart';
import 'miniflux_backend.dart';
import 'news_model.dart';

class FluentSearch extends StatelessWidget {
  const FluentSearch({super.key});

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();

    return FluxNewsSearchStatefulWrapper(onInit: () {
      initConfig(context, appState, appTheme);
    }, child: OrientationBuilder(builder: (context, orientation) {
      appState.orientation = orientation;
      return searchLayout(context, appState);
    }));
  }

  // initConfig reads the config values from the persistent storage and sets the state
  // accordingly.
  // It also initializes the database connection.
  Future<void> initConfig(BuildContext context, FluxNewsState appState,
      FluentAppTheme appTheme) async {
    await appState.readConfigValues();
    if (context.mounted) {
      appState.readConfig(context);
      if (appState.brightnessMode == FluxNewsState.brightnessModeDarkString) {
        appTheme.mode = ThemeMode.dark;
      } else if (appState.brightnessMode ==
          FluxNewsState.brightnessModeLightString) {
        appTheme.mode = ThemeMode.light;
      } else {
        appTheme.mode = ThemeMode.system;
      }
    }
  }

  Scaffold searchLayout(BuildContext context, FluxNewsState appState) {
    return Scaffold(
        appBar: AppBar(
          // set the title of the search page to search text field
          title: TextField(
            controller: appState.searchController,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchHint,
              hintStyle: Theme.of(context).textTheme.bodyLarge,
              border:
                  UnderlineInputBorder(borderRadius: BorderRadius.circular(2)),
              suffixIcon: IconButton(
                onPressed: () {
                  appState.searchController.clear();
                  appState.searchNewsList = Future<List<News>>.value([]);
                  appState.refreshView();
                },
                icon: const Icon(Icons.clear),
              ),
            ),

            // on change of the search text field, fetch the news list
            onSubmitted: (value) async {
              if (value != '') {
                // fetch the news list from the backend with the search text
                Future<List<News>> searchNewsListResult =
                    fetchSearchedNews(http.Client(), appState, value)
                        .onError((error, stackTrace) {
                  logThis(
                      'fetchSearchedNews',
                      'Caught an error in fetchSearchedNews function! : ${error.toString()}',
                      Level.error);
                  if (appState.errorString !=
                      AppLocalizations.of(context)!
                          .communicateionMinifluxError) {
                    appState.errorString = AppLocalizations.of(context)!
                        .communicateionMinifluxError;
                    appState.newError = true;
                    appState.refreshView();
                  }
                  return [];
                });
                // set the state with the fetched news list
                appState.searchNewsList = searchNewsListResult;
                appState.refreshView();
              } else {
                // if search text is empty, set the state with an empty list
                appState.searchNewsList = Future<List<News>>.value([]);
                appState.refreshView();
              }
            },
          ),
        ),
        // show the news list
        body: const FluentSearchNewsList());
  }
}

class FluxNewsSearchStatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const FluxNewsSearchStatefulWrapper(
      {super.key, required this.onInit, required this.child});
  @override
  FluxNewsBodyState createState() => FluxNewsBodyState();
}

// extend class to save actual scroll state of the list view
class FluxNewsBodyState extends State<FluxNewsSearchStatefulWrapper> {
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
