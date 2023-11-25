// the list view widget with search result
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:flux_news_desktop/news_card.dart';
import 'package:flux_news_desktop/news_model.dart';
import 'package:flux_news_desktop/news_row.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

class SearchNewsList extends StatelessWidget {
  const SearchNewsList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluxNewsState appState = context.watch<FluxNewsState>();
    bool searchView = true;
    var getData = FutureBuilder<List<News>>(
      future: appState.searchNewsList,
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
                      AppLocalizations.of(context)!.emptySearch,
                    ))
                  // show empty dialog if list is empty
                  : snapshot.data!.isEmpty
                      ? Center(
                          child: Text(
                          AppLocalizations.of(context)!.emptySearch,
                        ))
                      // otherwise create list view with the news of the search result
                      : Stack(children: [
                          ScrollablePositionedList.builder(
                              key: const PageStorageKey<String>(
                                  'NewsSearchList'),
                              itemCount: snapshot.data!.length,
                              itemScrollController:
                                  appState.searchItemScrollController,
                              itemPositionsListener:
                                  appState.searchItemPositionsListener,
                              initialScrollIndex: 0,
                              itemBuilder: (context, i) {
                                return NewsRow(
                                    news: snapshot.data![i],
                                    context: context,
                                    searchView: searchView);
                              }),
                        ]);
            }
        }
      },
    );
    return getData;
  }
}
