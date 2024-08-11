import 'package:fluent_ui/fluent_ui.dart';
import 'package:flux_news_desktop/state/flux_news_webview_state.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewMainView extends StatelessWidget {
  const WebViewMainView({
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    FluxNewsWebViewState webViewState = context.watch<FluxNewsWebViewState>();
    if (webViewState.isLoaded) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(FluentIcons.refresh),
                onPressed: () async {
                  await webViewState.controller.reload();
                },
              ),
              IconButton(
                icon: const Icon(FluentIcons.chrome_back),
                onPressed: () async {
                  await webViewState.controller.goBack();
                },
              ),
              IconButton(
                icon: const Icon(FluentIcons.chrome_back_mirrored),
                onPressed: () async {
                  await webViewState.controller.goForward();
                },
              ),
              IconButton(
                icon: const Icon(FluentIcons.chrome_close),
                onPressed: () async {
                  webViewState.closeWebview();
                },
              )
            ],
          ),
          Expanded(
              child: WebViewWidget(
            controller: webViewState.controller,
          ))
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
