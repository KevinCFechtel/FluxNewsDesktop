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
      return WebViewWidget(
        controller: webViewState.controller,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
