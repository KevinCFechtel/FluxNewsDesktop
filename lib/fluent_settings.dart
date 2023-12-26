import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database_backend.dart';
import 'package:flux_news_desktop/fluent_theme.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/news_model.dart';
import 'package:intl/intl.dart';
import 'package:my_logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:http/http.dart' as http;

import 'flux_news_state.dart';
import 'miniflux_backend.dart';

class FluentSettings extends StatelessWidget {
  const FluentSettings({super.key});

  // define the selection lists for the settings of saved news and starred news
  static const List<int> amountOfSavedNewsList = <int>[
    50,
    100,
    200,
    500,
    1000,
    2000
  ];
  static const List<int> amountOfSavedStarredNewsList = <int>[
    50,
    100,
    200,
    500,
    1000,
    2000
  ];

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();

    return FluxNewsSettingsStatefulWrapper(
        onInit: () {
          initConfig(context, appTheme);
        },
        child: ScaffoldPage(
            padding: EdgeInsets.zero,
            content: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                // this is the main column of the settings page
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // the first row contains the headline of the settings for the miniflux server
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.minifluxSettings,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            )),
                      ],
                    ),
                    // this list tile contains the url of the miniflux server
                    // it is clickable and opens a dialog to edit the url
                    ListTile(
                      leading: const Icon(
                        FluentIcons.link,
                      ),
                      title: Text(
                        '${AppLocalizations.of(context)!.apiUrl}: ${appState.minifluxURL ?? ''}',
                        //style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () {
                        _showURLEditDialog(context, appState);
                      },
                    ),
                    const Divider(),
                    // this list tile contains the api key of the miniflux server
                    // it is clickable and opens a dialog to edit the api key
                    ListTile(
                      leading: const Icon(
                        FluentIcons.return_key,
                      ),
                      title: Text(
                        '${AppLocalizations.of(context)!.apiKey}: ${appState.minifluxAPIKey ?? ''}',
                        //style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () {
                        _showApiKeyEditDialog(context, appState);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        FluentIcons.number_symbol,
                      ),
                      title: Text(
                        '${AppLocalizations.of(context)!.minifluxVersion}: ${appState.minifluxVersionString ?? ''}',
                        //style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () {
                        _showURLEditDialog(context, appState);
                      },
                    ),
                    // it there is an error on the authentication of the miniflux server
                    // there is shown a error message
                    appState.errorOnMinifluxAuth
                        ? appState.minifluxAPIKey != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: Text(
                                  AppLocalizations.of(context)!.authError,
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              )
                            : const SizedBox.shrink()
                        : const SizedBox.shrink(),
                    // this headline indicate the general settings section
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0, bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.generalSettings,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              )),
                        ],
                      ),
                    ),
                    // this row contains the selection of brightness mode
                    // there are the choices of light, dark and system
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.light,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!.brightnesMode,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ComboBox<KeyValueRecordType>(
                            value: appState.brightnessModeSelection,
                            items: appState.recordTypesBrightnessMode!
                                .map<ComboBoxItem<KeyValueRecordType>>(
                                    (recordType) =>
                                        ComboBoxItem<KeyValueRecordType>(
                                            value: recordType,
                                            child: Text(recordType.value)))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                if (value.key ==
                                    FluxNewsState.brightnessModeDarkString) {
                                  appTheme.mode = ThemeMode.dark;
                                } else if (value.key ==
                                    FluxNewsState.brightnessModeLightString) {
                                  appTheme.mode = ThemeMode.light;
                                } else {
                                  appTheme.mode = ThemeMode.system;
                                }
                                appState.brightnessMode = value.key;
                                appState.brightnessModeSelection = value;
                                appState.storage.write(
                                    key: FluxNewsState
                                        .secureStorageBrightnessModeKey,
                                    value: value.key);
                                appState.refreshView();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection of the mark as read on scroll over
                    // if it is turned on, a news is marked as read if it is scrolled over
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                              left: 17.0,
                            ),
                            child: Icon(
                              FluentIcons.accept,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .markAsReadOnScrollover,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ToggleSwitch(
                            checked: appState.markAsReadOnScrollOver,
                            onChanged: (bool value) {
                              String stringValue =
                                  FluxNewsState.secureStorageFalseString;
                              if (value == true) {
                                stringValue =
                                    FluxNewsState.secureStorageTrueString;
                              }
                              appState.markAsReadOnScrollOver = value;
                              appState.storage.write(
                                  key: FluxNewsState
                                      .secureStorageMarkAsReadOnScrollOverKey,
                                  value: stringValue);
                              appState.refreshView();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection of the sync on start
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.refresh,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!.syncOnStart,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ToggleSwitch(
                            checked: appState.syncOnStart,
                            onChanged: (bool value) {
                              String stringValue =
                                  FluxNewsState.secureStorageFalseString;
                              if (value == true) {
                                stringValue =
                                    FluxNewsState.secureStorageTrueString;
                              }
                              appState.syncOnStart = value;
                              appState.storage.write(
                                  key:
                                      FluxNewsState.secureStorageSyncOnStartKey,
                                  value: stringValue);
                              appState.refreshView();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection if the app bar text is multiline
                    // is turned on, the app bar text is showing the news count in the second line
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .multilineAppBarTextSetting,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ToggleSwitch(
                            checked: appState.multilineAppBarText,
                            onChanged: (bool value) {
                              String stringValue =
                                  FluxNewsState.secureStorageFalseString;
                              if (value == true) {
                                stringValue =
                                    FluxNewsState.secureStorageTrueString;
                              }
                              appState.multilineAppBarText = value;
                              appState.storage.write(
                                  key: FluxNewsState
                                      .secureStorageMultilineAppBarTextKey,
                                  value: stringValue);
                              appState.refreshView();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection if the feed icon is shown
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.image_crosshair,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .showFeedIconsTextSettings,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ToggleSwitch(
                            checked: appState.showFeedIcons,
                            onChanged: (bool value) {
                              String stringValue =
                                  FluxNewsState.secureStorageFalseString;
                              if (value == true) {
                                stringValue =
                                    FluxNewsState.secureStorageTrueString;
                              }
                              appState.showFeedIcons = value;
                              appState.storage.write(
                                  key: FluxNewsState
                                      .secureStorageShowFeedIconsTextKey,
                                  value: stringValue);
                              appState.refreshView();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection of the amount of saved news
                    // if the news exceeds the amount, the oldest news were deleted
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.save,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!.amountSaved,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ComboBox<int>(
                            value: appState.amountOfSavedNews,
                            items: amountOfSavedNewsList
                                .map<ComboBoxItem<int>>((int value) {
                              return ComboBoxItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                appState.amountOfSavedNews = value;
                                appState.storage.write(
                                    key: FluxNewsState
                                        .secureStorageAmountOfSavedNewsKey,
                                    value: value.toString());
                                appState.refreshView();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection of the amount of saved starred news
                    // if the news exceeds the amount, the oldest news were deleted
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.starburst,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!.amountSavedStarred,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ComboBox<int>(
                            value: appState.amountOfSavedStarredNews,
                            items: amountOfSavedStarredNewsList
                                .map<ComboBoxItem<int>>((int value) {
                              return ComboBoxItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                appState.amountOfSavedStarredNews = value;
                                appState.storage.write(
                                    key: FluxNewsState
                                        .secureStorageAmountOfSavedStarredNewsKey,
                                    value: value.toString());
                                appState.refreshView();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this row contains the selection if the debug mode is turned on
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 17.0),
                            child: Icon(
                              FluentIcons.developer_tools,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .debugModeTextSettings,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Spacer(),
                          ToggleSwitch(
                            checked: appState.debugMode,
                            onChanged: (bool value) {
                              String stringValue =
                                  FluxNewsState.secureStorageFalseString;
                              if (value == true) {
                                stringValue =
                                    FluxNewsState.secureStorageTrueString;
                              }
                              appState.debugMode = value;
                              appState.storage.write(
                                  key: FluxNewsState.secureStorageDebugModeKey,
                                  value: stringValue);
                              appState.refreshView();
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    // this list tile contains the ability to export the collected logs
                    ListTile(
                      leading: const Icon(
                        FluentIcons.import,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.exportLogs,
                        //style: Theme.of(context).textTheme.titleMedium,
                      ),
                      onPressed: () async {
                        String? outputFile = await FilePicker.platform.saveFile(
                          dialogTitle:
                              'Please select the destination for the exported logs:',
                          fileName: 'FluxNewsLogs.zip',
                        );

                        if (outputFile != null) {
                          ZipFileEncoder encoder = ZipFileEncoder();

                          encoder.create(outputFile);

                          List<Log> logs = await MyLogger.logs
                              .getByFilter(LogFilter.last24Hours());
                          DateTime now = DateTime.now();
                          DateFormat formatter = DateFormat('yyyy-MM-dd');
                          String formattedDate = formatter.format(now);
                          final directory =
                              await getApplicationDocumentsDirectory();
                          File logFile = File(
                              '${directory.path}/FluxNewsLogs-$formattedDate.log');
                          for (Log log in logs) {
                            logFile.writeAsStringSync(log.toString(),
                                mode: FileMode.append);
                          }
                          encoder.addFile(logFile);
                          encoder.close();
                        }
                      },
                    ),
                    const Divider(),
                    // this list tile delete the local news database
                    ListTile(
                      leading: Icon(
                        FluentIcons.delete,
                        color: Colors.red,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.deleteLocalCache,
                        /*style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(color: Colors.red),*/
                      ),
                      onPressed: () {
                        _showDeleteLocalCacheDialog(context, appState);
                      },
                    ),
                    const Divider(),
                    // this list tile contains the about dialog
                    /*
              AboutListTile(
                icon: const Icon(FluentIcons.info),
                applicationIcon: const Icon(
                  FontAwesomeFluentIcons.bookOpen,
                ),
                applicationName: FluxNewsState.applicationName,
                applicationVersion: FluxNewsState.applicationVersion,
                applicationLegalese: FluxNewsState.applicationLegalese,
                aboutBoxChildren: [
                  const SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: <TextSpan>[
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .descriptionMinifluxApp),
                        const TextSpan(
                            text: '${FluxNewsState.miniFluxProjectUrl}\n'),
                        TextSpan(
                            text: AppLocalizations.of(context)!
                                .descriptionMoreInformation),
                        const TextSpan(
                            text: FluxNewsState.applicationProjectUrl),
                      ],
                    ),
                  ),
                ],
              ),*/
                  ],
                ),
              ),
            )));
  }
}

// initConfig reads the config values from the persistent storage and sets the state
// accordingly.
// It also initializes the database connection.
Future<void> initConfig(BuildContext context, FluentAppTheme appTheme) async {
  FluxNewsState appState = context.read<FluxNewsState>();
  await appState.initLogging();
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
  appState.db = await appState.initializeDB();
  appState.refreshView();
}

// this method shows a dialog to enter the miniflux url
// the url is saved in the secure storage
// the url is matched against a regular expression for a valid https url
// if the api key is set, the connection is tested
Future _showURLEditDialog(BuildContext context, FluxNewsState appState) {
  bool errorInForm = false;
  TextEditingController controller = TextEditingController();
  if (appState.minifluxURL != null) {
    controller.text = appState.minifluxURL!;
  }
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return ContentDialog(
            title: Text(AppLocalizations.of(context)!.titleURL),
            content: Wrap(children: [
              Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(AppLocalizations.of(context)!.enterURL)),
              TextBox(
                controller: controller,
              ),
              errorInForm
                  ? Text(
                      AppLocalizations.of(context)!.enterValidURL,
                      style: TextStyle(color: Colors.red),
                    )
                  : const SizedBox.shrink()
            ]),
            actions: <Widget>[
              Button(
                onPressed: () =>
                    Navigator.pop(context, FluxNewsState.cancelContextString),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  String? newText;
                  RegExp regex = RegExp(FluxNewsState.urlValidationRegex);
                  if (!regex.hasMatch(controller.text)) {
                    setState(() {
                      errorInForm = true;
                    });
                  } else {
                    newText = controller.text;
                    if (appState.minifluxAPIKey != null &&
                        appState.minifluxAPIKey != '') {
                      bool authCheck = await checkMinifluxCredentials(
                              http.Client(),
                              newText,
                              appState.minifluxAPIKey!,
                              appState)
                          .onError((error, stackTrace) => false);

                      appState.errorOnMinifluxAuth = !authCheck;
                      appState.refreshView();
                    }
                    appState.storage.write(
                        key: FluxNewsState.secureStorageMinifluxURLKey,
                        value: newText);
                    appState.minifluxURL = newText;
                    if (context.mounted) {
                      Navigator.pop(context);
                      appState.refreshView();
                    }
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        });
      });
}

// this method shows a dialog to enter the miniflux api key
// the api key is saved in the secure storage
// if the url is set, the connection is tested
Future _showApiKeyEditDialog(BuildContext context, FluxNewsState appState) {
  TextEditingController controller = TextEditingController();
  if (appState.minifluxAPIKey != null) {
    controller.text = appState.minifluxAPIKey!;
  }
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: Text(AppLocalizations.of(context)!.titleAPIKey),
          content: Wrap(
            children: [
              Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(AppLocalizations.of(context)!.enterAPIKey)),
              TextBox(
                controller: controller,
              ),
            ],
          ),
          actions: <Widget>[
            Button(
              onPressed: () =>
                  Navigator.pop(context, FluxNewsState.cancelContextString),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () async {
                String? newText;
                if (controller.text != '') {
                  newText = controller.text;
                }
                if (appState.minifluxURL != null &&
                    appState.minifluxURL != '' &&
                    newText != null) {
                  bool authCheck = await checkMinifluxCredentials(http.Client(),
                          appState.minifluxURL!, newText, appState)
                      .onError((error, stackTrace) => false);
                  appState.errorOnMinifluxAuth = !authCheck;
                  appState.refreshView();
                }

                appState.storage.write(
                    key: FluxNewsState.secureStorageMinifluxAPIKey,
                    value: newText);
                appState.minifluxAPIKey = newText;
                if (context.mounted) {
                  Navigator.pop(context);
                  appState.refreshView();
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      });
}

// this method shows a dialog to enter the miniflux api key
// the api key is saved in the secure storage
// if the url is set, the connection is tested
Future _showDeleteLocalCacheDialog(
    BuildContext context, FluxNewsState appState) {
  TextEditingController controller = TextEditingController();
  if (appState.minifluxAPIKey != null) {
    controller.text = appState.minifluxAPIKey!;
  }
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title:
              Text(AppLocalizations.of(context)!.deleteLocalCacheDialogTitle),
          content: Wrap(children: [
            Text(AppLocalizations.of(context)!.deleteLocalCacheDialogContent),
          ]),
          actions: <Widget>[
            Button(
              onPressed: () =>
                  Navigator.pop(context, FluxNewsState.cancelContextString),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () async {
                deleteLocalNewsCache(appState, context);
                appState.newsList = Future<List<News>>.value([]);
                appState.categoryList =
                    Future<Categories>.value(Categories(categories: []));
                context.read<FluxNewsCounterState>().allNewsCount = 0;
                context.read<FluxNewsCounterState>().appBarNewsCount = 0;
                context.read<FluxNewsCounterState>().starredCount = 0;
                context.read<FluxNewsCounterState>().refreshView();
                appState.refreshView();
                Navigator.pop(context);
              },
              child: Text(
                AppLocalizations.of(context)!.ok,
              ),
            ),
          ],
        );
      });
}

class FluxNewsSettingsStatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const FluxNewsSettingsStatefulWrapper(
      {super.key, required this.onInit, required this.child});
  @override
  FluxNewsBodyState createState() => FluxNewsBodyState();
}

// extend class to save actual scroll state of the list view
class FluxNewsBodyState extends State<FluxNewsSettingsStatefulWrapper> {
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
