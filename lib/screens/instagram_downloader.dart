import 'package:downloader_app/services/ad_manager.dart';
import 'package:downloader_app/services/downloader_service.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';

import 'package:video_player/video_player.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

var getIt = GetIt.instance;

class InstagramDownloader extends StatefulWidget {
  const InstagramDownloader({Key key}) : super(key: key);
  static const route = 'instagram_downloader';
  static const icon = 'assets/044-instagram.png';
  static const name = 'Instagram';

  @override
  _InstagramDownloaderState createState() => _InstagramDownloaderState();
}

class _InstagramDownloaderState extends State<InstagramDownloader> {
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
  String fileName;

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
          backgroundColor: Colors.orange,
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Hero(
                tag: InstagramDownloader.route + "_icon",
                child: Image.asset(InstagramDownloader.icon,
                    width: 30, height: 30)),
            SizedBox(width: 10),
            Hero(
              tag: InstagramDownloader.route + "_name",
              transitionOnUserGestures: true,
              child: Material(
                type: MaterialType.transparency, // likely needed
                child: Container(
                  child: Text(
                    InstagramDownloader.name,
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
                } else {
                  Navigator.pop(context);
                }
              }),
        ),
        body: showDownload
            ? isVideo
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
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
                                        1.7) /* check for large video size, if so allow it to cover fullscreen */
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
                                                            videoMuted = false;
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
                                                  child:
                                                      VideoPlayer(_controller),
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
                                                          videoMuted = false;
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
                                    padding: EdgeInsets.symmetric(vertical: 20),
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
                          onPressed: !loading ? _startDownload : null,
                          color: Colors.orange,
                          child: Text(
                            "Download",
                            style: TextStyle(color: Colors.white),
                          ))
                    ],
                  )
            : Form(
                key: _formKey,
                child: Flex(
                  direction: Axis.vertical,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: TextFormField(
                              decoration: const InputDecoration(
                                hintText: '',
                                labelText:
                                    "Paste instagram post, video, reel, igtv link here.",
                              ),
                              onFieldSubmitted: (value) {
                                _handleSubmit(context);
                              },
                              enabled: !loading,
                              controller: myController,
                              validator: (String value) {
                                bool isValid = _tryValidate();
                                return !isValid ? 'Invalid url' : null;
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
                            color: Colors.orange,
                            disabledColor: Colors.orange.withAlpha(150),
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

    return regExp.hasMatch(text) &&
        (text.contains('instagram.com/p/') ||
            text.contains('instagram.com/reel/') ||
            text.contains('instagram.com/tv/'));
  }

  void _startDownload() async {
    DownloaderService.startDownload(
        context, (isVideo) ? largeVideo : largeImage, fileName);
  }

  void _handleSubmit(context) {
    if (_formKey.currentState.validate()) {
      setState(() {
        loading = true;
      });

      var url = Uri.parse(myController.text.trim());

      Map<String, String> queryParameters = {};

      queryParameters["__a"] = "1";
      var uri = Uri.https(url.authority, url.path, queryParameters);

      http.get(uri).then((response) async {
        if (response.statusCode == 200) {
          var data = jsonDecode(response.body);

          bool _isVideo = data["graphql"]["shortcode_media"]["is_video"];

          if (_isVideo) {
            isVideo = true;
            largeVideo = data["graphql"]["shortcode_media"]["video_url"];
          } else {
            isVideo = false;
            previewImage = data["graphql"]["shortcode_media"]
                ["display_resources"][0]["src"];

            largeImage = data["graphql"]["shortcode_media"]["display_resources"]
                [2]["src"];
          }

          if (isVideo) {
            _controller = VideoPlayerController.network(largeVideo);
            _controller.setLooping(true);
            _controller.setVolume(0);
            await _controller.initialize();
          }

          setState(() {
            showDownload = true;
            loading = false;
            if (isVideo) {
              topText = "Video posted by @" +
                  data["graphql"]["shortcode_media"]["owner"]["username"] +
                  " [" +
                  data["graphql"]["shortcode_media"]["owner"]["full_name"] +
                  "]";
              fileName = data["graphql"]["shortcode_media"]["owner"]
                      ["username"] +
                  "_" +
                  data["graphql"]["shortcode_media"]["id"] +
                  ".mp4";
            } else {
              topText = "Image posted by @" +
                  data["graphql"]["shortcode_media"]["owner"]["username"] +
                  " [" +
                  data["graphql"]["shortcode_media"]["owner"]["full_name"] +
                  "]";
              fileName = data["graphql"]["shortcode_media"]["owner"]
                      ["username"] +
                  "_" +
                  data["graphql"]["shortcode_media"]["id"] +
                  ".jpeg";
            }
            AdManager.tryPreloadInterstitial();
          });

          if (isVideo) _controller.play();
        } else if (response.statusCode == 404) {
          DownloaderService.showSnackbar(_scaffoldKey.currentState,
              "The post is private or link is broken.");

          setState(() {
            showDownload = false;
            loading = false;
            videoMuted = true;
          });

          await getIt<SentryClient>().captureException(
            exception: InstagramEx("Instagram"),
            stackTrace:
                {"type": "Broken link ", "url": uri.toString()}.toString(),
          );
        }
      }).catchError((error, stackTrace) async {
        print(error);
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(content: Text("Oops! Something went wrong.")));
        setState(() {
          showDownload = false;
          loading = false;
          videoMuted = true;
        });
        await getIt<SentryClient>().captureException(
          exception: error,
          stackTrace: stackTrace,
        );
      });
    }
  }
}

class InstagramEx implements Exception {
  String cause;
  InstagramEx(this.cause);
}
