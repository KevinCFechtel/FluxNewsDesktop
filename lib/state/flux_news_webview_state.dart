import 'package:fluent_ui/fluent_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FluxNewsWebViewState extends ChangeNotifier {
  // TEST Webview
  WebViewController controller = WebViewController();

  Future<bool> loadWebPage(String url) async {
    controller.loadRequest(Uri.parse(url));
    notifyListeners();
    return true;
  }

  // notify the listeners of FluxNewsState to refresh views
  void refreshView() {
    notifyListeners();
  }
}
