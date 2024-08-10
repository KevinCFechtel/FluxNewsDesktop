import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:my_logger/core/constants.dart';
import 'package:my_logger/logger.dart';

void logThis(String module, String message, LogLevel loglevel,
    {Exception? exception, StackTrace? stackTrace}) {
  MyLogger.log(
      className: FluxNewsState.logTag,
      methodName: module,
      text: message,
      type: loglevel,
      exception: exception,
      stacktrace: stackTrace);
}
