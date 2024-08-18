// the list view widget with search result
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_news_row.dart';
import 'package:flux_news_desktop/state/flux_news_state.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_news_card.dart';
import 'package:flux_news_desktop/models/news_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class FluentSearchNewsList extends StatelessWidget {
  const FluentSearchNewsList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                          SuperListView.builder(
                              key: const PageStorageKey<String>('NewsSearchList'),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, i) {
                                return width <= 1300
                                    ? FluentNewsCard(news: snapshot.data![i], context: context, searchView: searchView)
                                    : FluentNewsRow(news: snapshot.data![i], context: context, searchView: searchView);
                              }),
                        ]);
            }
        }
      },
    );
    return getData;
  }
}
