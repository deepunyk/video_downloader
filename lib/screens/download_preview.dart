import 'dart:io';

import 'package:downloader_app/components/audio_control.dart';
import 'package:downloader_app/services/downloader_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';
import 'package:share/share.dart';
import 'package:video_player/video_player.dart';

var getIt = GetIt.instance;

class DownloadPreview extends StatefulWidget {
  const DownloadPreview({
    Key key,
    this.task,
  }) : super(key: key);

  final DownloadTask task;

  @override
  _DownloadPreviewState createState() => _DownloadPreviewState();
}

class _DownloadPreviewState extends State<DownloadPreview> {
  bool _loaded = false;
  VideoPlayerController _controller;
  bool _isVideo;
  bool _isAudio;
  bool videoMuted = true;
  String _isError = "";

  File file;

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    file = new File(widget.task.savedDir + '/' + widget.task.filename);
    _checkExistance().then((exists) async {
      if (exists) {
        bool isVideo = file.path.split('.').last == 'mp4';
        bool isAudio = file.path.split('.').last == 'mp3' ||
            file.path.split('.').last == 'm4a';

        if (isVideo) {
          try {
            _controller = VideoPlayerController.file(file);
            _controller.setLooping(true);
            _controller.setVolume(0);
            await _controller.initialize();
            setState(() {
              _isVideo = true;
              _isAudio = false;
              _loaded = true;
            });
          } catch (error, stackTrace) {
            print(error);
            setState(() {
              _isError = "There was an error playing the video.";
              _loaded = true;
              _isVideo = false;
              _isAudio = false;
            });
            await getIt<SentryClient>().captureException(
              exception: error,
              stackTrace: stackTrace,
            );
          }
        } else if (isAudio) {
          setState(() {
            _isVideo = false;
            _isAudio = true;
            _loaded = true;
          });
        } else {
          setState(() {
            _isVideo = false;
            _isAudio = false;
            _loaded = true;
          });
        }
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  Future<bool> _checkExistance() async {
    if (file == null || (await file.exists()) == false) {
      await showDialog(
        context: context,
        child: AlertDialog(
          title: Text("file not found!"),
          actions: [
            FlatButton(
              child: Text("Ok"),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            )
          ],
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_loaded)
              Align(
                  alignment: Alignment.center,
                  child: CircularProgressIndicator()),
            if (_loaded)
              Container(
                  color: Colors.black,
                  child: _isVideo
                      ? _controller.value.initialized
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: SizedBox(
                                  width: _controller.value.aspectRatio,
                                  height: 1,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                            )
                          : Center(
                              child: CircularProgressIndicator(),
                            )
                      : (_isAudio)
                          ? Center(
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints.tight(Size.fromHeight(50)),
                                child: AudioControl(
                                    colorsInverted: true,
                                    networkSrc: file.path,
                                    autostart: false),
                              ),
                            )
                          : ((_isError == ""))
                              ? Image.file(
                                  file,
                                  fit: BoxFit.fitWidth,
                                )
                              : Center(
                                  child: Text(
                                    _isError,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                )),
            if (_loaded)
              Positioned(
                right: 10,
                bottom: 60,
                child: Row(
                  children: [
                    if (_isVideo) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Material(
                          color: Colors.blue, // button color
                          child: InkWell(
                              splashColor: Colors.white, // inkwell color
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _controller.value.isPlaying
                                        ? Icon(Icons.pause)
                                        : Icon(Icons.play_arrow)
                                  ],
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              }),
                        ),
                      ),
                      SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Material(
                          color: Colors.blue, // button color
                          child: InkWell(
                              splashColor: Colors.white, // inkwell color
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    videoMuted
                                        ? Icon(Icons.volume_off)
                                        : Icon(Icons.volume_up)
                                  ],
                                ),
                              ),
                              onTap: () {
                                if (videoMuted) {
                                  _controller.setVolume(1);
                                  setState(() {
                                    videoMuted = false;
                                  });
                                } else {
                                  _controller.setVolume(0);
                                  setState(() {
                                    videoMuted = true;
                                  });
                                }
                              }),
                        ),
                      )
                    ],
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      child: Material(
                        color: Colors.blue, // button color
                        child: InkWell(
                            splashColor: Colors.white, // inkwell color
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [Icon(Icons.share)],
                              ),
                            ),
                            onTap: () {
                              Share.shareFiles([file.path]);
                            }),
                      ),
                    ),
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      child: Material(
                        color: Colors.red, // button color
                        child: InkWell(
                            splashColor: Colors.white, // inkwell color
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [Icon(Icons.delete)],
                              ),
                            ),
                            onTap: () {
                              DownloaderService.deletePrompt(
                                      context, widget.task)
                                  .then((value) {
                                if (value != null && value == true) {
                                  Navigator.of(context).pop(true);
                                }
                              });
                            }),
                      ),
                    ),
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      child: Material(
                        color: Colors.grey, // button color
                        child: InkWell(
                            splashColor: Colors.white, // inkwell color
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  )
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                            }),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
