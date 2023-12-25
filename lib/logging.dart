import 'package:flux_news_desktop/flux_news_state.dart';
import 'package:my_logger/core/constants.dart';
import 'package:my_logger/logger.dart';

void logThis(String module, String message, LogLevel loglevel) {
  /*
  if (appState.loggingFilePath != "") {
    DateTime now = DateTime.now();
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String formattedDate = formatter.format(now);
    File logFile =
        File('${appState.loggingFilePath}/FluxNewsLogs-$formattedDate.log');
    String logMessage = "${FluxNewsState.logTag} - $module : $message";
    Logger logger = Logger(
      filter: ProductionFilter(),
      printer: SimplePrinter(printTime: true, colors: false),
      output: MultiOutput([FileOutput(file: logFile), ConsoleOutput()]),
    );
    logger.log(loglevel, logMessage);
  } else {
    String logMessage = "${FluxNewsState.logTag} - $module : $message";
    Logger logger = Logger(
      printer: PrettyPrinter(methodCount: 0),
    );
    logger.log(loglevel, logMessage);
  }
  */

  MyLogger.log(
    className: FluxNewsState.logTag,
    methodName: module,
    text: message,
    type: loglevel,
  );
}
