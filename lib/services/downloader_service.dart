import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:downloader_app/config.dart';
import 'package:downloader_app/services/ad_manager.dart';
import 'package:downloader_app/services/download_progress_broadcast.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

final getIt = GetIt.instance;

class DownloaderService {
  static const DB_NAME = "download_tasks.db";

  static Future<dynamic> showSnackbar(ScaffoldState cntxt, txt) async {
    cntxt.hideCurrentSnackBar();
    var completer = new Completer();
    cntxt.showSnackBar(SnackBar(
      content: Container(
        decoration: BoxDecoration(
            color: Colors.grey[850], borderRadius: BorderRadius.circular(5)),
        margin: EdgeInsets.fromLTRB(0, 0, 0, AdManager.bannershown ? 30 : 0),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Text(
          txt,
          style: TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 1000,
      behavior: SnackBarBehavior.floating,
    ));
    Future.delayed(Duration(seconds: 2)).then((value) {
      completer.complete();
    });
    return completer.future;
  }

  static Future<Directory> ensureDirectory() async {
    final externalDir = await ExtStorage.getExternalStorageDirectory();
    var downloaderDir = new Directory('$externalDir/${Configs.APP_FOLDER}');

    if (!await downloaderDir.exists()) await downloaderDir.create();
    return downloaderDir;
  }

  static Future<bool> copyWhatsappStatus(
      BuildContext context, ScaffoldState scaffold, File ogStatus) async {
    try {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        var downloaderDir = await ensureDirectory();
        var filename = ogStatus.path.split("/").last;
        File fileToBeDownloaded = new File('${downloaderDir.path}/$filename');

        if (await fileToBeDownloaded.exists() &&
            (await FlutterDownloader.loadTasksWithRawQuery(
                        query:
                            'SELECT * FROM task where file_name=\'$filename\''))
                    .length !=
                0) {
          await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Status is already saved.'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    },
                    child: Text('Ok'),
                  ),
                ],
              );
            },
          );
          return false;
        } else {
          var db = await openDatabase(DB_NAME, version: 2);

          var stuff = await db.rawQuery('SELECT * FROM task ORDER BY _id DESC');
          var uuid = Uuid();

          var onk = 0;
          if (stuff.length > 0) {
            onk = stuff[0]["_id"];
          }
          await db.insert('task', {
            "_id": onk + 1,
            "task_id": uuid.v4(),
            "url": '',
            "status": 3,
            "progress": 100,
            "file_name": filename,
            "saved_dir": '/storage/emulated/0/${Configs.APP_FOLDER}',
            "headers": '',
            "mime_type": filename.split('.').last == 'jpeg' ||
                    filename.split('.').last == 'jpg'
                ? 'image/jpeg'
                : 'video/mp4',
            "resumable": 0,
            "show_notification": 1,
            "open_file_from_notification": 1,
            "time_created": DateTime.now().millisecondsSinceEpoch,
          });
          await db.close();

          await ogStatus.copy(fileToBeDownloaded.path);

          showSnackbar(scaffold, "Status saved.");
          AdManager.showInstantInterstitialAd();

          getIt<DownloadProgressBroadcast>().incrementDownloadCount();

          return true;
        }
      } else {
        print("permission denied ooooo");
        showSnackbar(scaffold, "Storage Permission not granted.");
        return false;
      }
    } catch (err, stackTrace) {
      print(err);
      showSnackbar(scaffold, "An error occured during copying.");
      await getIt<SentryClient>().captureException(
        exception: errorTextConfiguration,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  static Future startDownload(context, url, filename) async {
    try {
      final status = await Permission.storage.request();
      String prefix = "";
      if (status.isGranted) {
        var downloaderDir = await ensureDirectory();

        File fileToBeDownloaded = new File('${downloaderDir.path}/$filename');
        if (await fileToBeDownloaded.exists()) {
          bool result = await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('File Already Exists'),
                content: Text('Do you want to save again?'),
                actions: <Widget>[
                  new FlatButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(
                          false); // dismisses only the dialog and returns false
                    },
                    child: Text('No'),
                  ),
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(
                          true); // dismisses only the dialog and returns true
                    },
                    child: Text('Yes'),
                  ),
                ],
              );
            },
          );

          if (!(result == true)) return;

          var rng = new Random();
          prefix = rng.nextInt(100000).toString() + "_";
        }
        await FlutterDownloader.enqueue(
          url: url,
          savedDir: downloaderDir.path,
          fileName: prefix + filename,
          requiresStorageNotLow: true,
          openFileFromNotification: true,
          showNotification: true,
        );
        getIt<DownloadProgressBroadcast>().incrementDownloadCount();
      } else {
        print("Permission denied");
        showSnackbar(Scaffold.of(context),
            "Please grant the storage permission to save status.");
      }
    } catch (error, stackTrace) {
      await getIt<SentryClient>().captureException(
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<bool> deletePrompt(
      BuildContext context, DownloadTask task) async {
    String result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to remove the file?'),
          actions: <Widget>[
            FlatButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(
                    "delete"); // dismisses only the dialog and returns true
              },
              child: Text(
                'Remove and Delete File',
                style: TextStyle(color: Colors.red),
              ),
            ),
            new FlatButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(
                    "remove"); // dismisses only the dialog and returns false
              },
              child: Text('Remove'),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(
                    "cancel"); // dismisses only the dialog and returns true
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result == null || result == "cancel") return false;

    if (result == "remove") {
      await FlutterDownloader.remove(
          taskId: task.taskId, shouldDeleteContent: false);
      return true;
    }

    if (result == "delete") {
      await FlutterDownloader.remove(
          taskId: task.taskId, shouldDeleteContent: true);
      return true;
    }
    return false;
  }
}
