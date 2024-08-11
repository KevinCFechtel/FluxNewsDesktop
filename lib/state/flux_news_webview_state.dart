import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class FluxNewsWebViewState extends ChangeNotifier {
  // TEST Webview

  WebViewController macWebController = WebViewController();
  WebviewController windowsWebController = WebviewController();
  bool isLoaded = false;

  Future<void> loadWebPage(String url) async {
    if (Platform.isMacOS) {
      macWebController.loadRequest(Uri.parse(url));
      isLoaded = true;
    } else if (Platform.isWindows) {
      String? checkRequirements = await WebviewController.getWebViewVersion();
      if (checkRequirements != null) {
        windowsWebController.loadUrl(url);
        isLoaded = true;
      }
    }

    notifyListeners();
  }

  Future<void> pageBack() async {
    if (Platform.isMacOS) {
      macWebController.goBack();
    } else if (Platform.isWindows) {
      windowsWebController.goBack();
    }
  }

  Future<void> pageForward() async {
    if (Platform.isMacOS) {
      macWebController.goForward();
    } else if (Platform.isWindows) {
      windowsWebController.goForward();
    }
  }

  Future<void> pageReload() async {
    if (Platform.isMacOS) {
      macWebController.reload();
    } else if (Platform.isWindows) {
      windowsWebController.reload();
    }
  }

  void closeWebview() {
    if (Platform.isMacOS) {
      macWebController = WebViewController();
    } else if (Platform.isWindows) {
      windowsWebController = WebviewController();
    }
    isLoaded = false;
    notifyListeners();
  }

  // notify the listeners of FluxNewsState to refresh views
  void refreshView() {
    notifyListeners();
  }
}
