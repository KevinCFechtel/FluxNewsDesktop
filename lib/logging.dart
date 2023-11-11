import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:logger/logger.dart';

void logThis(String module, String message, Level loglevel) {
  String logMessage = "${FluxNewsState.logTag} - $module : $message";
  LogEvent(loglevel, logMessage);
}
