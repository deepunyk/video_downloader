import 'dart:typed_data';

import 'package:downloader_app/services/downloader_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:downloader_app/screens/download_preview.dart';
import 'package:downloader_app/services/download_progress_broadcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

final getIt = GetIt.instance;

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({Key key}) : super(key: key);

  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

final _scaffoldKey = GlobalKey<ScaffoldState>();

// Future<dynamic> snackAlert(ScaffoldState cntxt, txt) async {
//   var completer = new Completer();
//   cntxt.showSnackBar(SnackBar(content: Text(txt)));
//   Future.delayed(Duration(seconds: 2)).then((value) {
//     completer.complete();
//   });
//   return completer.future;
// }

class _DownloadsPageState extends State<DownloadsPage> {
  List<DownloadTask> currentlyDownloading = [];

  bool isListening = false;
  String isgranted = "";
  @override
  void initState() {
    super.initState();
    getIt<DownloadProgressBroadcast>().resetDownloadCount();

    Permission.storage.request().then((value) {
      if (value.isGranted) {
        _getDownloadingTasks();
        if (!isListening) {
          getIt<DownloadProgressBroadcast>()
              .progressStream
              .listen(_handleStream);
          isListening = true;
        }

        isgranted = "yes";
      } else {
        setState(() {
          isgranted = "no";
        });
      }
    });
  }

  void _handleStream(message) {
    if (message.isEmpty || message == [] || message.length == 0) {
      return;
    }
    print(message);
    if (message.elementAt(0) == "reload") {
      if (mounted)
        return setState(() {});
      else
        return;
    }

    if (message[1] == DownloadTaskStatus(2)) {
      // FlutterDownloader.pause(taskId: message[0]);
      if (mounted) _updateTaskProgress(message[0], message[2]);
    } else if (message[1] == DownloadTaskStatus(3) ||
        message[1] == DownloadTaskStatus(1) ||
        message[1] == DownloadTaskStatus(5) ||
        message[1] == DownloadTaskStatus(6)) {
      if (mounted) {
        _getDownloadingTasks();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  _updateTaskProgress(String id, int progress) async {
    print(progress);
    if (!mounted) return;
    var pos =
        currentlyDownloading.indexWhere((element) => element.taskId == id);

    if (pos == -1) {
      return;
    }

    setState(() {
      var newState = DownloadTask(
          filename: currentlyDownloading[pos].filename,
          progress: progress,
          savedDir: currentlyDownloading[pos].savedDir,
          status: currentlyDownloading[pos].status,
          taskId: currentlyDownloading[pos].taskId,
          timeCreated: currentlyDownloading[pos].timeCreated,
          url: currentlyDownloading[pos].url);
      currentlyDownloading[pos] = newState;
    });
  }

  Future<List<DownloadTask>> _getCompletedDownloads() async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query: 'SELECT * FROM task WHERE status=3 ORDER BY time_created DESC');
    return tasks;
  }

  _getDownloadingTasks() async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(
        query:
            'SELECT * FROM task WHERE status IN (2, 6, 1) ORDER BY time_created DESC');
    setState(() {
      currentlyDownloading = tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isgranted == "")
      return Container();
    else if (isgranted == "no") {
      return Scaffold(
        body: Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text("Please grant the permission to see the statuses!"),
                      SizedBox(
                        height: 10,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Material(
                          color: Colors.black, // button color
                          child: InkWell(
                              splashColor: Colors.red, // inkwell color
                              child: Container(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "Grant Storage Permission",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              onTap: () {
                                Permission.storage.request().then((status) {
                                  if (status.isGranted) {
                                    setState(() {
                                      isgranted = "yes";
                                    });
                                  }
                                });
                              }),
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      );
    } else if (isgranted == "yes")
      return Scaffold(
        key: _scaffoldKey,
        body: SafeArea(
          child: Container(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._buildDownloading(),
                  ..._buildDownloaded(),
                ],
              ),
            ),
          ),
        ),
      );
    else
      return Container();
  }

  List<Widget> _buildDownloading() {
    return [
      if ((currentlyDownloading?.length ?? 0) > 0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20)
              .copyWith(
            bottom: 22,
          ),
          child: Text(
            "Currently Downloading",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black45),
          ),
        ),
      ListView.builder(
          itemCount: currentlyDownloading?.length ?? 0,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (_, idx) {
            var task = currentlyDownloading[idx];
            return DownloadingTaskItem(key: Key(task.taskId), task: task);
          })
    ];
  }

  List<Widget> _buildDownloaded() {
    return [
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20).copyWith(
          bottom: 22,
        ),
        child: Text(
          "Downloads",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black45),
        ),
      ),
      FutureBuilder<List<DownloadTask>>(
        future: _getCompletedDownloads(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data.length > 0)
              return ListView.builder(
                  itemCount: snapshot.data.length,
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (_, idx) {
                    DownloadTask task = snapshot.data[idx];

                    return DownloadedTaskItem(
                        key: Key(task.taskId + "okok"), task: task);
                  });
            else
              return Container(
                child: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                    Image.asset(
                      'assets/empty-downloads.png',
                      width: 220,
                    ),
                    SizedBox(height: 50),
                    Text("No downloads found."),
                  ],
                )),
              );
          }

          return Container();
        },
      )
    ];
  }
}

class DownloadingTaskItem extends StatelessWidget {
  const DownloadingTaskItem({Key key, this.task}) : super(key: key);
  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    Widget _icon = Icon(Icons.arrow_downward);
    if (task.status == DownloadTaskStatus.enqueued) {
      _icon = Icon(Icons.hourglass_empty);
    } else if (task.status == DownloadTaskStatus.paused) {
      _icon = Icon(Icons.pause_circle_filled);
    } else if (task.status == DownloadTaskStatus.canceled) {
      _icon = Icon(Icons.error);
    }
    return Material(
      key: Key(task.taskId + "_dti"),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (task.status == DownloadTaskStatus.enqueued) {
              DownloaderService.showSnackbar(_scaffoldKey.currentState,
                  "Download is added to queue, it will start shortly.");
            } else if (task.status == DownloadTaskStatus.paused) {
              if (await FlutterDownloader.resume(taskId: task.taskId) == null) {
                FlutterDownloader.remove(taskId: task.taskId);
              }
              getIt<DownloadProgressBroadcast>().addIntoSink(["reload"]);
            } else if (task.status == DownloadTaskStatus.canceled) {
              FlutterDownloader.remove(taskId: task.taskId);
              getIt<DownloadProgressBroadcast>().addIntoSink(["reload"]);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 56,
                margin: EdgeInsets.symmetric(horizontal: 6),
                height: 56,
                color: Colors.grey[200],
                child: _icon,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(task.filename,
                          style: TextStyle(fontWeight: FontWeight.w400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: EdgeInsets.only(
                          right: 15, left: 10, top: 2, bottom: 5),
                      width: double.infinity,
                      child: LinearProgressIndicator(
                        value: task.progress / 100,
                        valueColor: task.status == DownloadTaskStatus.paused
                            ? AlwaysStoppedAnimation<Color>(Colors.orange)
                            : AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DownloadedTaskItem extends StatefulWidget {
  const DownloadedTaskItem({Key key, this.task}) : super(key: key);
  final DownloadTask task;

  @override
  _DownloadedTaskItemState createState() => _DownloadedTaskItemState();
}

class _DownloadedTaskItemState extends State<DownloadedTaskItem> {
  Widget _preview = Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
      ),
    ),
  );
  bool _missingFile = false;
  File _file;
  @override
  void initState() {
    super.initState();
    _file = File('${widget.task.savedDir}/${widget.task.filename}');
    _checkExistance();
  }

  _checkExistance() async {
    if (await _file.exists()) {
      if (_file.path.split('.').last == 'jpeg' ||
          _file.path.split('.').last == 'jpg') {
        if (mounted)
          setState(() {
            _preview = Image.file(_file);
          });
      } else if (_file.path.split('.').last == 'mp4') {
        Uint8List uint8list = await VideoThumbnail.thumbnailData(
          video: _file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 300,
          maxHeight: 300,
          quality: 10,
        );
        if (mounted)
          setState(() {
            _preview = Image.memory(
              uint8list,
              fit: BoxFit.cover,
              width: 54,
            );
          });
      } else if (_file.path.split('.').last == 'mp3' ||
          _file.path.split('.').last == 'm4a') {
        if (mounted)
          setState(() {
            _preview = Icon(Icons.audiotrack);
          });
      }
    } else {
      if (mounted)
        setState(() {
          _missingFile = true;
          _preview = Icon(Icons.error);
        });
    }
  }

  void _handleTap() async {
    if (_missingFile) {
      await DownloaderService.showSnackbar(
          _scaffoldKey.currentState, "Oops! Looks like the file was deleted.");
      await FlutterDownloader.remove(taskId: widget.task.taskId);
      if (mounted) getIt<DownloadProgressBroadcast>().addIntoSink(["reload"]);
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DownloadPreview(
              task: widget.task,
            ),
          )).then((value) {
        if (value != null && value == true) {
          _scaffoldKey.currentState.hideCurrentSnackBar();
          DownloaderService.showSnackbar(
              _scaffoldKey.currentState, "This file has been removed.");
          if (mounted)
            getIt<DownloadProgressBroadcast>().addIntoSink(["reload"]);
        }
      });
    }
  }

  Widget build(BuildContext context) {
    return Material(
      key: Key(widget.task.taskId + "_ddti"),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 56,
                margin: EdgeInsets.symmetric(horizontal: 6),
                height: 56,
                color: Colors.grey[200],
                child: _preview,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(widget.task.filename,
                          style: TextStyle(fontWeight: FontWeight.w400),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: EdgeInsets.only(
                          right: 15, left: 10, top: 2, bottom: 5),
                      width: double.infinity,
                      child: Text(
                        timeago.format(DateTime.fromMillisecondsSinceEpoch(
                            widget.task.timeCreated)),
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
