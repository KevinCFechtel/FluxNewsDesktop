import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class FluxNewsWebViewState extends ChangeNotifier {
  // TEST Webview

  WebViewController? macWebController;
  WebviewController? windowsWebController;
  bool isLoaded = false;
  String webViewTitle = "";

  void initWebViewState() {
    if (Platform.isMacOS) {
      macWebController = WebViewController();
    } else if (Platform.isWindows) {
      windowsWebController = WebviewController();
      if (windowsWebController != null) {
        windowsWebController!.initialize();
      }
    }
  }

  Future<void> loadWebPage(String url) async {
    if (Platform.isMacOS) {
      if (macWebController != null) {
        macWebController!.loadRequest(Uri.parse(url));
        isLoaded = true;
      }
    } else if (Platform.isWindows) {
      String? checkRequirements = await WebviewController.getWebViewVersion();
      if (checkRequirements != null) {
        if (windowsWebController != null) {
          windowsWebController!.loadUrl(url);
          isLoaded = true;
        }
      }
    }

    notifyListeners();
  }

  Future<void> pageBack() async {
    if (Platform.isMacOS) {
      if (macWebController != null) {
        macWebController!.goBack();
      }
    } else if (Platform.isWindows) {
      if (windowsWebController != null) {
        windowsWebController!.goBack();
      }
    }
  }

  Future<void> pageForward() async {
    if (Platform.isMacOS) {
      if (macWebController != null) {
        macWebController!.goForward();
      }
    } else if (Platform.isWindows) {
      if (windowsWebController != null) {
        windowsWebController!.goForward();
      }
    }
  }

  Future<void> pageReload() async {
    if (Platform.isMacOS) {
      if (macWebController != null) {
        macWebController!.reload();
      }
    } else if (Platform.isWindows) {
      if (windowsWebController != null) {
        windowsWebController!.reload();
      }
    }
  }

  void closeWebview() {
    if (Platform.isMacOS) {
      macWebController = WebViewController();
    } else if (Platform.isWindows) {
      windowsWebController = WebviewController();
      if (windowsWebController != null) {
        windowsWebController!.initialize();
      }
    }
    webViewTitle = "";
    isLoaded = false;
    notifyListeners();
  }

  void setTitle(String title) {
    webViewTitle = title;
    notifyListeners();
  }

  // notify the listeners of FluxNewsState to refresh views
  void refreshView() {
    notifyListeners();
  }
}
