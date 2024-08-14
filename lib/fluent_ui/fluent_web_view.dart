import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/fluent_ui/fluent_theme.dart';
import 'package:flux_news_desktop/state/flux_news_webview_state.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:flutter_gen/gen_l10n/flux_news_localizations.dart';

class WebViewMainView extends StatelessWidget {
  const WebViewMainView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    FluxNewsWebViewState webViewState = context.watch<FluxNewsWebViewState>();
    FluentAppTheme appTheme = context.watch<FluentAppTheme>();
    if (webViewState.isLoaded) {
      return Container(
        color: appTheme.backgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 0, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.newsViewer,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      )),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
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
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      FluentIcons.chrome_close,
                      size: 15,
                    ),
                    onPressed: () async {
                      webViewState.closeWebview();
                    },
                  )
                ],
              ),
            ),
            Expanded(
                child: Platform.isMacOS
                    ? webViewState.macWebController != null
                        ? WebViewWidget(
                            controller: webViewState.macWebController!,
                          )
                        : Container(
                            color: appTheme.backgroundColor,
                            child: const Column(children: [SizedBox.shrink()]))
                    : webViewState.windowsWebController != null
                        ? Webview(webViewState.windowsWebController!)
                        : Container(
                            color: appTheme.backgroundColor,
                            child: const Column(children: [SizedBox.shrink()])))
          ],
        ),
      );
    } else {
      return Container(
          color: appTheme.backgroundColor,
          child: const Column(children: [SizedBox.shrink()]));
    }
  }
}
