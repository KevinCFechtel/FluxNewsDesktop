import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FluxNewsWebViewState extends ChangeNotifier {
  InAppWebViewController? webController;
  bool isLoaded = false;
  String webViewTitle = "";
  HeadlessInAppWebView? webView;
  InAppWebViewSettings settings = InAppWebViewSettings(
      mediaPlaybackRequiresUserGesture: false, allowsInlineMediaPlayback: true, transparentBackground: true);

  Future<void> loadWebPage(String url) async {
    if (webController != null) {
      webController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    } else {
      webView = HeadlessInAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        onWebViewCreated: (controller) async {
          webController = controller;
        },
        initialSettings: settings,
      );
      if (webView != null) {
        webView!.run();
      }
    }

    isLoaded = true;
    notifyListeners();
  }

  Future<void> pageBack() async {
    if (webController != null) {
      webController!.goBack();
    }
  }

  Future<void> pageForward() async {
    if (webController != null) {
      webController!.goForward();
    }
  }

  Future<void> pageReload() async {
    if (webController != null) {
      webController!.reload();
    }
  }

  void closeWebview() {
    if (webController != null) {
      webController!.dispose();
    }
    webController = null;
    webViewTitle = "";
    isLoaded = false;
    notifyListeners();
  }

  void setTitle(String title) {
    webViewTitle = title;
    notifyListeners();
  }

  void refreshView() {
    notifyListeners();
  }
}
