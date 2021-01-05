import 'dart:async';

import 'package:downloader_app/services/ad_manager.dart';
import 'package:downloader_app/services/downloader_service.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

var getIt = GetIt.instance;

class FacebookDownloader extends StatefulWidget {
  const FacebookDownloader({Key key}) : super(key: key);
  static const route = 'facebook_downloader';
  static const icon = 'assets/024-facebook.png';
  static const name = 'Facebook';

  @override
  _FacebookDownloaderState createState() => _FacebookDownloaderState();
}

class _FacebookDownloaderState extends State<FacebookDownloader> {
  final myController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  VideoPlayerController _controller;

  bool loading = false;
  bool showDownload = false;

  String previewImage;
  String largeImage;
  String largeVideo;
  bool isVideo;
  bool videoMuted = true;
  String topText = "";
  String fileName = "";

  @override
  void dispose() {
    myController.dispose();
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (showDownload) {
          setState(() {
            showDownload = false;
            videoMuted = true;
          });
          try {
            if (_controller != null && _controller?.value?.isPlaying == true) {
              await _controller?.pause();
            }
          } catch (err) {
            print(err);
          }
          return Future.value(false);
        } else {
          return Future.value(true);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.lightBlue,
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Hero(
                tag: FacebookDownloader.route + "_icon",
                child: Image.asset(FacebookDownloader.icon,
                    width: 30, height: 30)),
            SizedBox(width: 10),
            Hero(
              tag: FacebookDownloader.route + "_name",
              transitionOnUserGestures: true,
              child: Material(
                type: MaterialType.transparency, // likely needed
                child: Container(
                  child: Text(
                    FacebookDownloader.name,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ]),
          leading: IconButton(
              icon: Icon(showDownload ? Icons.close : Icons.arrow_back),
              onPressed: () async {
                if (showDownload) {
                  setState(() {
                    showDownload = false;
                    videoMuted = true;
                  });

                  try {
                    if (_controller != null &&
                        _controller?.value?.isPlaying == true) {
                      await _controller?.pause();
                    }
                  } catch (err) {
                    print(err);
                  }
                } else
                  Navigator.pop(context);
              }),
        ),
        body: showDownload
            ? Center(
                child: isVideo
                    ? _controller.value.initialized
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                            child: Stack(
                              children: [
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        topText,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    ((_controller.value.size.height /
                                                _controller.value.size.width) >=
                                            1.7)
                                        ? Flexible(
                                            child: Stack(
                                              fit: StackFit.passthrough,
                                              children: [
                                                if (_controller != null)
                                                  VideoPlayer(_controller),
                                                if (_controller != null)
                                                  Positioned(
                                                    top: 00,
                                                    right: 20,
                                                    width: 42,
                                                    height: 42,
                                                    child: ClipOval(
                                                      child: Material(
                                                        color: Colors
                                                            .blue, // button color
                                                        child: InkWell(
                                                          splashColor: Colors
                                                              .red, // inkwell color
                                                          child: SizedBox(
                                                              width: 56,
                                                              height: 56,
                                                              child: videoMuted
                                                                  ? Icon(Icons
                                                                      .volume_off)
                                                                  : Icon(Icons
                                                                      .volume_up)),
                                                          onTap: () {
                                                            if (videoMuted) {
                                                              _controller
                                                                  .setVolume(1);
                                                              setState(() {
                                                                videoMuted =
                                                                    false;
                                                              });
                                                            } else {
                                                              _controller
                                                                  .setVolume(0);
                                                              setState(() {
                                                                videoMuted =
                                                                    true;
                                                              });
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        : Stack(
                                            fit: StackFit.passthrough,
                                            children: [
                                              if (_controller != null)
                                                FittedBox(
                                                    fit: BoxFit.cover,
                                                    child: SizedBox(
                                                      width: _controller
                                                          .value.size.width,
                                                      height: _controller
                                                          .value.size.height,
                                                      child: VideoPlayer(
                                                          _controller),
                                                    )),
                                              if (_controller != null)
                                                Positioned(
                                                  top: 20,
                                                  right: 20,
                                                  width: 42,
                                                  height: 42,
                                                  child: ClipOval(
                                                    child: Material(
                                                      color: Colors
                                                          .blue, // button color
                                                      child: InkWell(
                                                        splashColor: Colors
                                                            .red, // inkwell color
                                                        child: SizedBox(
                                                            width: 56,
                                                            height: 56,
                                                            child: videoMuted
                                                                ? Icon(Icons
                                                                    .volume_off)
                                                                : Icon(Icons
                                                                    .volume_up)),
                                                        onTap: () {
                                                          if (videoMuted) {
                                                            _controller
                                                                .setVolume(1);
                                                            setState(() {
                                                              videoMuted =
                                                                  false;
                                                            });
                                                          } else {
                                                            _controller
                                                                .setVolume(0);
                                                            setState(() {
                                                              videoMuted = true;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                    FlatButton(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 20),
                                        onPressed: !loading
                                            ? () {
                                                _startDownload();
                                              }
                                            : null,
                                        color: Colors.orange,
                                        child: Text(
                                          "Download",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                    SizedBox(
                                      height: 55,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Container()
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(topText,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Image.network(
                            previewImage,
                            fit: BoxFit.fitWidth,
                          ),
                          FlatButton(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              onPressed: !loading ? () {} : null,
                              color: Colors.orange,
                              child: Text(
                                "Download",
                                style: TextStyle(color: Colors.white),
                              ))
                        ],
                      ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: TextFormField(
                        decoration: const InputDecoration(
                          hintText: '',
                          labelText:
                              "paste facebook video link (public profile or page only)",
                        ),
                        onFieldSubmitted: (value) {
                          _handleSubmit(context);
                        },
                        enabled: !loading,
                        controller: myController,
                        validator: (String value) {
                          bool isValid = _tryValidate();
                          return !isValid ? 'Invalid instagram post url' : null;
                        },
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    FlatButton(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      onPressed: !loading
                          ? () {
                              _handleSubmit(context);
                            }
                          : null,
                      color: Colors.lightBlue,
                      disabledColor: Colors.lightBlue.withAlpha(150),
                      child: !loading
                          ? Text(
                              "Submit",
                              style: TextStyle(color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Loading"),
                                SizedBox(width: 10),
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(),
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

  bool _tryValidate() {
    RegExp regExp =
        new RegExp(r'(?:(?:https):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');

    var text = myController.text;

    return regExp.hasMatch(text) && (text.contains('facebook.com'));
  }

  void _handleSubmit(context) {
    if (_formKey.currentState.validate()) {
      setState(() {
        loading = true;
      });

      http.get(myController.text.trim(), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.47 Safari/537.36'
      }).then((response) async {
        if (response.statusCode == 200) {
          var data = (response.body);

          RegExp regexRateLimit = new RegExp(r'sd_src_no_ratelimit:"([^"]+)"');
          RegExp regexSrc = new RegExp(r'/sd_src:"([^"]+)"/');
          RegExp regexId = new RegExp(r'#(\d+)/?$#');

          var sdvideo = regexRateLimit.stringMatch(data);
          var hdvideo = regexSrc.stringMatch(data);

          fileName = regexId.stringMatch(data) ??
              myController.text.trim().split('/posts/')[1]?.split("/")[0] +
                  '.mp4';

          if (sdvideo != null || hdvideo != null) {
            isVideo = true;
          } else
            isVideo = false;

          if (hdvideo != null) {
            largeVideo = hdvideo.split('"')[1].split('"')[0];
          } else if (sdvideo != null) {
            largeVideo = sdvideo.split('"')[1].split('"')[0];
          }

          if (isVideo != null && isVideo == true) {
            _controller = VideoPlayerController.network(largeVideo);
            _controller.setLooping(true);
            _controller.setVolume(0);
            await _controller.initialize();
          }

          // check image

          if (!(isVideo == true)) {
            DownloaderService.showSnackbar(
                _scaffoldKey.currentState, "Invalid video link!");
            setState(() {
              showDownload = false;
              loading = false;
              videoMuted = true;
            });
          } else {
            setState(() {
              showDownload = true;
              loading = false;
              videoMuted = true;
            });
            AdManager.tryPreloadInterstitial();
          }

          if (isVideo != null && isVideo == true) {
            await _controller.play();
          }
        } else {
          DownloaderService.showSnackbar(
              _scaffoldKey.currentState, "Invalid link!!");
          setState(() {
            showDownload = false;
            loading = false;
            videoMuted = true;
          });
          getIt<SentryClient>().captureException(
            exception: FacebookEx("Facebook 404"),
            stackTrace: myController.text.toString(),
          );
        }
      }).catchError((error, stackTrace) {
        DownloaderService.showSnackbar(
            _scaffoldKey.currentState, "Oops! Something went wrong.");
        setState(() {
          showDownload = false;
          loading = false;
          videoMuted = true;
        });
        getIt<SentryClient>().captureException(
          exception: error,
          stackTrace: stackTrace,
        );
      });
    }
  }

  _startDownload() {
    DownloaderService.startDownload(context, largeVideo, fileName);
  }
}

class FacebookEx implements Exception {
  String cause;
  FacebookEx(this.cause);
}
