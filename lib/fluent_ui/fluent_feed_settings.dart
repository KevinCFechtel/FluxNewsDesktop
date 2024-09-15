import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database/database_backend.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_feed_settings_list.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

import '../state/flux_news_state.dart';

class FluentFeedSettings extends StatelessWidget {
  const FluentFeedSettings({super.key});

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();

    return FluxNewsFeedSettingsStatefulWrapper(onInit: () {
      initConfig(context, appState, appTheme);
      appState.feedSettingsList = queryFeedsFromDB(appState, context);
    }, child: OrientationBuilder(builder: (context, orientation) {
      appState.orientation = orientation;
      return feedSettingsLayout(context, appState);
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

  ScaffoldPage feedSettingsLayout(BuildContext context, FluxNewsState appState) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(AppLocalizations.of(context)!.feedSettings,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
            )),
      ),
      content: const FluentFeedSettingsList(),
    );
  }
}

class FluxNewsFeedSettingsStatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const FluxNewsFeedSettingsStatefulWrapper({super.key, required this.onInit, required this.child});
  @override
  FluxNewsBodyState createState() => FluxNewsBodyState();
}

// extend class to save actual scroll state of the list view
class FluxNewsBodyState extends State<FluxNewsFeedSettingsStatefulWrapper> {
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
