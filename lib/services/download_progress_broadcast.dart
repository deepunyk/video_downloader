import 'dart:async';

import 'package:sentry/sentry.dart';
import 'package:get_it/get_it.dart';

var getIt = GetIt.instance;

class DownloadProgressBroadcast {
  final _subject = StreamController<List>.broadcast();
  final _newDownload = StreamController<int>.broadcast();
  int count = 0;
  DownloadProgressBroadcast() {
    print("initialising");
  }

  Stream<List> get progressStream => _subject.stream;
  Stream<int> get newDownloadCountStream => _newDownload.stream;

  void addIntoSink(List x) {
    _subject.sink.add(x);
  }

  void incrementDownloadCount() async {
    try {
      count++;
      _newDownload.sink.add(count);
      print("ok");
    } catch (error, stackTrace) {
      // TODO: ignore error here

      _newDownload.sink.add(1);
      print("first boi");
    }
  }

  void resetDownloadCount() {
    count = 0;
    _newDownload.sink.add(0);
  }

  dispose() {
    _subject.close();
    _newDownload.close();
  }
}
