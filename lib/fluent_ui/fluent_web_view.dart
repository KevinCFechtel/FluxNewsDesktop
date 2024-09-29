import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_theme.dart';
import 'package:flux_news_desktop/state/flux_news_webview_state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

class WebViewMainView extends StatelessWidget {
  const WebViewMainView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();
    FluxNewsWebViewState webViewState = context.watch<FluxNewsWebViewState>();

    return Container(
      color: appTheme.backgroundColor,
      child: Column(
        children: [
          webViewState.isLoaded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 0, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      FilledButton(
                          onPressed: () {
                            webViewState.closeWebview();
                          },
                          child: Text(AppLocalizations.of(context)!.done)),
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(webViewState.webViewTitle, overflow: TextOverflow.ellipsis))),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: IconButton(
                          icon: const Icon(
                            FluentIcons.chrome_back,
                            size: 15,
                          ),
                          onPressed: () async {
                            await webViewState.pageBack();
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          FluentIcons.chrome_back_mirrored,
                          size: 15,
                        ),
                        onPressed: () async {
                          await webViewState.pageForward();
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          FluentIcons.refresh,
                          size: 15,
                        ),
                        onPressed: () async {
                          await webViewState.pageReload();
                        },
                      ),
                    ],
                  ),
                )
              : Container(color: appTheme.backgroundColor, child: const Column(children: [SizedBox.shrink()])),
          Expanded(
              child: webViewState.isLoaded
                  ? InAppWebView(
                      headlessWebView: webViewState.webView,
                      onWebViewCreated: (controller) {
                        webViewState.webView = null;
                        webViewState.webController = controller;
                      },
                    )
                  : Container(color: appTheme.backgroundColor, child: const Column(children: [SizedBox.shrink()])))
        ],
      ),
    );
  }
}
