import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/database_backend.dart';
import 'package:flux_news_desktop/fluent_theme.dart';
import 'package:flux_news_desktop/flux_news_counter_state.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:flux_news_desktop/logging.dart';
import 'package:flux_news_desktop/news_model.dart';
import 'package:flux_news_desktop/news_widget_functions.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

// here we define the appearance of the news cards
class NewsRow extends StatelessWidget {
  const NewsRow({
    super.key,
    required this.news,
    required this.context,
    required this.searchView,
  });
  final News news;
  final BuildContext context;
  final bool searchView;

  @override
  Widget build(BuildContext context) {
    final contextController = FlyoutController();
    final contextAttachKey = GlobalKey();
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();
    FluxNewsState appState = context.watch<FluxNewsState>();
    FluxNewsCounterState appCounterState =
        context.watch<FluxNewsCounterState>();
    return FlyoutTarget(
        key: contextAttachKey,
        controller: contextController,
        child: Card(
          // inkwell is used for the onTab and onLongPress functions
          child: GestureDetector(
            onTap: () async {
              // on tab we update the status of the news to read and open the news
              try {
                updateNewsStatusInDB(
                    news.newsID, FluxNewsState.readNewsStatus, appState);
              } catch (e) {
                logThis(
                    'updateNewsStatusInDB',
                    'Caught an error in updateNewsStatusInDB function! : ${e.toString()}',
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
              // update the status to read on the news list and notify the categories
              // to recalculate the news count
              news.status = FluxNewsState.readNewsStatus;

              context.read<FluxNewsCounterState>().listUpdated = true;
              context.read<FluxNewsCounterState>().refreshView();
              appState.refreshView();

              // there are difference on launching the news url between the platforms
              // on android and ios it's preferred to check first if the link can be opened
              // by an installed app, if not then the link is opened in a web-view within the app.
              // on macos we open directly the web-view within the app.
              /*
          if (Platform.isAndroid) {
            AndroidUrlLauncher.launchUrl(context, news.url);
          } else if (Platform.isIOS) {
            // catch exception if no app is installed to handle the url
            final bool nativeAppLaunchSucceeded = await launchUrl(
              Uri.parse(news.url),
              mode: LaunchMode.externalNonBrowserApplication,
            );
            //if exception is caught, open the app in web-view
            if (!nativeAppLaunchSucceeded) {
              await launchUrl(
                Uri.parse(news.url),
                mode: LaunchMode.inAppWebView,
              );
            }
          } else if (Platform.isMacOS) {
            await launchUrl(
              Uri.parse(news.url),
              mode: LaunchMode.externalApplication,
            );
          }
          */
            },
            onSecondaryTapUp: (d) {
              // This calculates the position of the flyout according to the parent navigator
              final targetContext = contextAttachKey.currentContext;
              if (targetContext == null) return;
              final box = targetContext.findRenderObject() as RenderBox;
              final position = box.localToGlobal(
                d.localPosition,
                ancestor: Navigator.of(context).context.findRenderObject(),
              );
              contextController.showFlyout(
                  barrierColor: Colors.black.withOpacity(0.1),
                  position: position,
                  builder: (context) {
                    return FlyoutContent(
                      child: SizedBox(
                        width: 220.0,
                        height: 150,
                        child: CommandBar(
                          direction: Axis.vertical,
                          isCompact: false,
                          primaryItems: [
                            CommandBarButton(
                              icon: news.starred
                                  ? const Icon(FluentIcons.favorite_star)
                                  : const Icon(FluentIcons.favorite_star_fill),
                              label: news.starred
                                  ? Text(AppLocalizations.of(context)!
                                      .deleteBookmark)
                                  : Text(AppLocalizations.of(context)!
                                      .addBookmark),
                              onPressed: () async {
                                await markAsBookmarkContextFunction(
                                    news, appState, context, searchView);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            CommandBarButton(
                              icon: news.status == FluxNewsState.readNewsStatus
                                  ? const Icon(FluentIcons.location_fill)
                                  : const Icon(FluentIcons.location_circle),
                              label: news.status == FluxNewsState.readNewsStatus
                                  ? Text(AppLocalizations.of(context)!
                                      .markAsUnread)
                                  : Text(
                                      AppLocalizations.of(context)!.markAsRead),
                              onPressed: () {
                                // switch between bookmarked or not bookmarked depending on the previous status
                                if (news.status ==
                                    FluxNewsState.readNewsStatus) {
                                  markNewsAsReadContextAction(news, appState,
                                      context, searchView, appCounterState);
                                } else {
                                  markNewsAsUnreadContextAction(news, appState,
                                      context, searchView, appCounterState);
                                }
                                Navigator.pop(context);
                              },
                            ),
                            CommandBarButton(
                              icon: const Icon(FluentIcons.save),
                              label: Text(
                                AppLocalizations.of(context)!.contextSaveButton,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                news.getImageURL() != FluxNewsState.noImageUrlString
                    ? Expanded(
                        flex: searchView
                            ? context.select(
                                    (FluxNewsState model) => model.isTablet)
                                ? 4
                                : 5
                            : 5,
                        child: FastCachedImage(
                          url: news.getImageURL(),
                          height: 230,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          errorBuilder: (context, url, error) => const Icon(
                            FluentIcons.error,
                          ),
                        ),
                      )
                    // if no image is available, shrink this widget
                    : const SizedBox.shrink(),
                Expanded(
                  flex: searchView
                      ? context.select((FluxNewsState model) => model.isTablet)
                          ? 7
                          : 5
                      : 5,
                  child: ListTile(
                    title: Text(
                      news.title,
                      style: news.status == FluxNewsState.unreadNewsStatus
                          ? appTheme.unreadText
                          : appTheme.readText,
                    ),
                    subtitle: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 2.0,
                          ),
                          child: Row(
                            children: [
                              news.status == FluxNewsState.unreadNewsStatus
                                  ? const Padding(
                                      padding: EdgeInsets.only(right: 15.0),
                                      child: SizedBox(
                                          width: 15,
                                          height: 35,
                                          child: Icon(
                                            FluentIcons.location_fill,
                                          )))
                                  : const SizedBox.shrink(),
                              appState.showFeedIcons
                                  ? Padding(
                                      padding:
                                          const EdgeInsets.only(right: 5.0),
                                      child: news.getFeedIcon(16.0, context))
                                  : const SizedBox.shrink(),
                              Padding(
                                padding: const EdgeInsets.only(left: 0.0),
                                child: Text(
                                  news.feedTitle,
                                  style: news.status ==
                                          FluxNewsState.unreadNewsStatus
                                      ? appTheme.unreadText
                                      : appTheme.readText,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  context
                                      .read<FluxNewsState>()
                                      .dateFormat
                                      .format(news.getPublishingDate()),
                                  style: news.status ==
                                          FluxNewsState.unreadNewsStatus
                                      ? appTheme.unreadText
                                      : appTheme.readText,
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                height: 35,
                                child: news.starred
                                    ? Icon(
                                        FluentIcons.favorite_star_fill,
                                        color: news.status ==
                                                FluxNewsState.unreadNewsStatus
                                            ? appTheme.unreadText.color
                                            : appTheme.readText.color,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        // here is the news text, the Opacity decide between read and unread
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0, bottom: 10),
                          child: Text(
                            news.getText(),
                            style: news.status == FluxNewsState.unreadNewsStatus
                                ? appTheme.unreadText
                                : appTheme.readText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
