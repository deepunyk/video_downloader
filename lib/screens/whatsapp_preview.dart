import 'dart:async';
import 'dart:io';

import 'package:downloader_app/services/downloader_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WhatsappPreview extends StatefulWidget {
  const WhatsappPreview({Key key, this.file}) : super(key: key);
  static const route = 'whatsapp_preview';
  final File file;

  @override
  _WhatsappPreviewState createState() => _WhatsappPreviewState();
}

class _WhatsappPreviewState extends State<WhatsappPreview> {
  bool _loaded = false;
  VideoPlayerController _controller;
  bool _isVideo;
  bool videoMuted = true;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool forceReload = false;

  @override
  void dispose() {
    if (_controller != null) {
      try {
        _controller?.pause();
      } catch (err) {}
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    try {
      if (_controller != null) {
        _controller?.pause();
      }
    } catch (err) {}
    super.deactivate();
  }

  @override
  void initState() {
    super.initState();

    _checkExistance().then((exists) async {
      if (exists) {
        bool isVideo = widget.file.path.split('.').last == 'mp4';
        if (isVideo) {
          _controller = VideoPlayerController.file(widget.file);
          _controller.setLooping(true);
          _controller.setVolume(0);
          await _controller.initialize();

          setState(() {
            _isVideo = true;
            _loaded = true;
          });
          await _controller.play();
        } else {
          setState(() {
            _isVideo = false;
            _loaded = true;
          });
        }
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  Future<bool> _checkExistance() async {
    if (widget.file == null || (await widget.file.exists()) == false) {
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
    return WillPopScope(
      onWillPop: () {
        print("WILL POP");
        _controller?.pause();
        Navigator.pop(context, forceReload);
        return Future.value(false);
      },
      child: Scaffold(
        key: _scaffoldKey,
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
                        : Image.file(
                            widget.file,
                            fit: BoxFit.fitWidth,
                          )),
              if (_loaded)
                Positioned(
                  right: 10,
                  bottom: 60,
                  child: Row(
                    children: [
                      if (_isVideo)
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
                        ),
                      SizedBox(width: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        child: Material(
                          color: Colors.blue, // button color
                          child: InkWell(
                              splashColor: Colors.white, // inkwell color
                              child: Container(
                                width: 100,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "SAVE",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Icon(
                                      Icons.file_download,
                                      color: Colors.white,
                                    )
                                  ],
                                ),
                              ),
                              onTap: () {
                                DownloaderService.copyWhatsappStatus(
                                        _scaffoldKey.currentContext,
                                        _scaffoldKey.currentState,
                                        widget.file)
                                    .then((value) {
                                  print("NIGA NIGA NIGA");
                                  print(value);
                                  if (value != null && value == true)
                                    setState(() {
                                      forceReload = value;
                                    });
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
                                print("FORCE RELOAD IS ");
                                print(forceReload);
                                Navigator.pop(context, forceReload);
                              }),
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
