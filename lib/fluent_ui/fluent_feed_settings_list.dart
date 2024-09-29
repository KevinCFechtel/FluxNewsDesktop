// the list view widget with search result
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:flux_news_desktop/database/database_backend.dart';
import 'package:flux_news_desktop/models/news_model.dart';
import 'package:flux_news_desktop/state/flux_news_state.dart';
import 'package:provider/provider.dart';

class FluentFeedSettingsList extends StatelessWidget {
  const FluentFeedSettingsList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    var getData = FutureBuilder<List<Feed>>(
      future: appState.feedSettingsList,
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
                      AppLocalizations.of(context)!.emptyFeedList,
                    ))
                  // show empty dialog if list is empty
                  : snapshot.data!.isEmpty
                      ? Center(
                          child: Text(
                          AppLocalizations.of(context)!.emptyFeedList,
                        ))
                      // otherwise create list view with the news of the search result
                      : ListView(children: [
                          for (Feed feed in snapshot.data!) showFeed(feed, context),
                        ]);
            }
        }
      },
    );
    return getData;
  }

  // here we style the category ExpansionTile
  // we use a ExpansionTile because we want to show the according feeds
  // of this category in the expanded state.
  Widget showFeed(Feed feed, BuildContext context) {
    FluxNewsState appState = context.read<FluxNewsState>();
    return Expander(
      leading: feed.getFeedIcon(16.0, context),
      // make the title clickable to select this category as the news view
      header: Text(
        feed.title,
        overflow: TextOverflow.ellipsis,
      ),
      // iterate over the according feeds of the category
      content: Column(
        children: [
          appState.truncateMode == 2
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 17.0, right: 12.0),
                        child: Icon(
                          FluentIcons.cut,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.manualTruncate,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      ToggleSwitch(
                        checked: feed.manualTruncate == null ? false : feed.manualTruncate!,
                        onChanged: (bool value) async {
                          feed.manualTruncate = value;
                          await updateManualTruncateStatusOfFeedInDB(feed.feedID, value, appState);
                          // reload the news list with the new filter
                          appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                            appState.jumpToItem(0);
                          });
                          appState.refreshView();
                        },
                      ),
                    ],
                  ))
              : const SizedBox.shrink(),
          appState.truncateMode == 2 ? const Divider() : const SizedBox.shrink(),
          Padding(
            padding: EdgeInsets.only(top: appState.truncateMode == 2 ? 10 : 0, bottom: 10),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 17.0, right: 12.0),
                  child: Icon(
                    FluentIcons.code,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.preferParagraph,
                    overflow: TextOverflow.visible,
                  ),
                ),
                ToggleSwitch(
                  checked: feed.preferParagraph == null ? false : feed.preferParagraph!,
                  onChanged: (bool value) async {
                    feed.preferParagraph = value;
                    await updatePreferParagraphStatusOfFeedInDB(feed.feedID, value, appState);
                    // reload the news list with the new filter
                    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                      appState.jumpToItem(0);
                    });
                    appState.refreshView();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 17.0, right: 12.0),
                  child: Icon(
                    FluentIcons.image_pixel,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.preferAttachmentImage,
                    overflow: TextOverflow.visible,
                  ),
                ),
                ToggleSwitch(
                  checked: feed.preferAttachmentImage == null ? false : feed.preferAttachmentImage!,
                  onChanged: (bool value) async {
                    feed.preferAttachmentImage = value;
                    await updatePreferAttachmentImageStatusOfFeedInDB(feed.feedID, value, appState);
                    // reload the news list with the new filter
                    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                      appState.jumpToItem(0);
                    });
                    appState.refreshView();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 17.0, right: 12.0),
                  child: Icon(
                    FluentIcons.brightness,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.manualAdaptLightModeToIcon,
                    overflow: TextOverflow.visible,
                  ),
                ),
                ToggleSwitch(
                  checked: feed.manualAdaptLightModeToIcon == null ? false : feed.manualAdaptLightModeToIcon!,
                  onChanged: (bool value) async {
                    feed.manualAdaptLightModeToIcon = value;
                    await updateManualAdaptLightModeToIconStatusOfFeedInDB(feed.feedID, value, appState);
                    if (context.mounted) {
                      appState.categoryList = queryCategoriesFromDB(appState, context);
                    }

                    // reload the news list with the new filter
                    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                      appState.jumpToItem(0);
                    });
                    appState.refreshView();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 17.0, right: 12.0),
                  child: Icon(
                    FluentIcons.brightness,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.manualAdaptDarkModeToIcon,
                    overflow: TextOverflow.visible,
                  ),
                ),
                ToggleSwitch(
                  checked: feed.manualAdaptDarkModeToIcon == null ? false : feed.manualAdaptDarkModeToIcon!,
                  onChanged: (bool value) async {
                    feed.manualAdaptDarkModeToIcon = value;
                    await updateManualAdaptDarkModeToIconStatusOfFeedInDB(feed.feedID, value, appState);
                    if (context.mounted) {
                      appState.categoryList = queryCategoriesFromDB(appState, context);
                    }

                    // reload the news list with the new filter
                    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                      appState.jumpToItem(0);
                    });
                    appState.refreshView();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 10),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 17.0, right: 12.0),
                  child: Icon(
                    FluentIcons.account_browser,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.openMinifluxEntry,
                    overflow: TextOverflow.visible,
                  ),
                ),
                ToggleSwitch(
                  checked: feed.openMinifluxEntry == null ? false : feed.openMinifluxEntry!,
                  onChanged: (bool value) async {
                    feed.openMinifluxEntry = value;
                    await updateOpenMinifluxEntryStatusOfFeedInDB(feed.feedID, value, appState);

                    // reload the news list with the new filter
                    appState.newsList = queryNewsFromDB(appState, appState.feedIDs).whenComplete(() {
                      appState.jumpToItem(0);
                    });
                    appState.refreshView();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
