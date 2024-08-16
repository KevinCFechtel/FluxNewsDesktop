import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_theme.dart';
import 'package:flux_news_desktop/functions/logging.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_search_news_list.dart';
import 'package:my_logger/core/constants.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

import '../state/flux_news_state.dart';
import '../miniflux_backend/miniflux_backend.dart';
import '../models/news_model.dart';

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
  Future<void> initConfig(BuildContext context, FluxNewsState appState, FluentAppTheme appTheme) async {
    await appState.readConfigValues();
    if (context.mounted) {
      appState.readConfig(context);
      if (appState.brightnessMode == FluxNewsState.brightnessModeDarkString) {
        appTheme.mode = ThemeMode.dark;
      } else if (appState.brightnessMode == FluxNewsState.brightnessModeLightString) {
        appTheme.mode = ThemeMode.light;
      } else {
        appTheme.mode = ThemeMode.system;
      }
    }
  }

  ScaffoldPage searchLayout(BuildContext context, FluxNewsState appState) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: TextBox(
        controller: appState.searchController,
        placeholder: AppLocalizations.of(context)!.searchHint,
        suffix: IconButton(
          onPressed: () {
            appState.searchController.clear();
            appState.searchNewsList = Future<List<News>>.value([]);
            appState.refreshView();
          },
          icon: const Icon(FluentIcons.clear),
        ),
        onSubmitted: (value) {
          if (value != '') {
            // fetch the news list from the backend with the search text
            Future<List<News>> searchNewsListResult =
                fetchSearchedNews(http.Client(), appState, value).onError((error, stackTrace) {
              logThis('fetchSearchedNews', 'Caught an error in fetchSearchedNews function! : ${error.toString()}',
                  LogLevel.ERROR,
                  stackTrace: stackTrace);
              if (context.mounted) {
                if (appState.errorString != AppLocalizations.of(context)!.communicateionMinifluxError) {
                  appState.errorString = AppLocalizations.of(context)!.communicateionMinifluxError;
                  appState.newError = true;
                  appState.refreshView();
                }
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
      content: const FluentSearchNewsList(),
    );
  }
}

class FluxNewsSearchStatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const FluxNewsSearchStatefulWrapper({super.key, required this.onInit, required this.child});
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
