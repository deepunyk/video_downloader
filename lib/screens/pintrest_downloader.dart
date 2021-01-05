///(?<=images\":).*?(?=,\"price_value)/
///   /https?:\/\/(i.pinimg.com)\/originals(.+?).jpg/s.exec(document.body.innerText)[0]
/// /(V_720P":{"url":")(.+?)mp4/s.exec(document.body.innerText)[0]

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:downloader_app/services/ad_manager.dart';
import 'package:downloader_app/services/downloader_service.dart';
import 'package:get_it/get_it.dart';
import 'package:html/parser.dart';
import 'package:sentry/sentry.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

var getIt = GetIt.instance;

class PintrestDownloader extends StatefulWidget {
  const PintrestDownloader({Key key}) : super(key: key);
  static const route = 'pintrest_downloader';
  static const icon = 'assets/066-pinterest.png';
  static const name = 'Pinterest';

  @override
  _PintrestDownloaderState createState() => _PintrestDownloaderState();
}

class _PintrestDownloaderState extends State<PintrestDownloader> {
  final myController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  VideoPlayerController _controller;

  bool loading = false;
  bool showDownload = false;

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
          backgroundColor: Colors.red[900],
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Hero(
                tag: PintrestDownloader.route + "_icon",
                child: Image.asset(PintrestDownloader.icon,
                    width: 30, height: 30)),
            SizedBox(width: 10),
            Hero(
              tag: PintrestDownloader.route + "_name",
              transitionOnUserGestures: true,
              child: Material(
                type: MaterialType.transparency, // likely needed
                child: Container(
                  child: Text(
                    PintrestDownloader.name,
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
                child: isVideo // Is Video
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
                        // Is Image
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
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.60),
                            child: Image.network(
                              largeImage,
                              fit: BoxFit.fitHeight,
                            ),
                          ),
                          Expanded(
                            child: Container(),
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
                          SizedBox(height: 60),
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
                              "Paste pinterest pin link here (video or image)",
                        ),
                        onFieldSubmitted: (value) {
                          _handleSubmit(context);
                        },
                        enabled: !loading,
                        controller: myController,
                        validator: (String value) {
                          bool isValid = _tryValidate();
                          return !isValid ? 'Invalid pinterest pin url' : null;
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
                      color: Colors.red[900],
                      disabledColor: Colors.red[900].withAlpha(150),
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

    return regExp.hasMatch(text) &&
        (text.contains('pinterest.com/pin/') || text.contains('pin.it'));
  }

  void _handleSubmit(context) async {
    if (_formKey.currentState.validate()) {
      setState(() {
        loading = true;
      });

      var tempText = myController.text.trim();

      tempText = tempText.replaceAll('/feedback/', '');
      tempText = tempText.split("?")[0];
      var finalUrl = tempText;
      if (tempText.contains('pin.it')) {
        HttpClient client = new HttpClient();
        HttpClientResponse response = await client
            .getUrl(Uri.parse(tempText))
            .then((HttpClientRequest request) {
          request.headers.add('User-Agent',
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.47 Safari/537.36');
          return request.close();
        });

        if (response.statusCode != 200) {
          DownloaderService.showSnackbar(
              _scaffoldKey.currentState, "Invalid link!");
          setState(() {
            showDownload = false;
            loading = false;
            videoMuted = true;
          });
          return;
        }

        // Process the response.

        finalUrl = (response?.redirects?.last?.location).toString();

        finalUrl = finalUrl.replaceAll('/feedback/', '');
        finalUrl = finalUrl.replaceAll('/sent/', '');
        finalUrl = finalUrl.split("?")[0];
      }

      http.get(finalUrl, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.47 Safari/537.36'
      }).then((response) async {
        if (response.statusCode == 200) {
          var data = (response.body);
          var document = parse(data);
          RegExp regexRateLimit =
              new RegExp(r'https?:\/\/(i.pinimg.com)\/originals(.+?).jpg');
          RegExp regexSrc = new RegExp(r'(V_720P":{"url":")(.+?)mp4');
          RegExp regexId = new RegExp(r'pin\/(.+?)\/');

          var videoLink = regexSrc.stringMatch(data);
          var imageLink = regexRateLimit.stringMatch(data);
          print(http.Response);
          // print(response.);
          var id;
          try {
            id = regexId
                .stringMatch(finalUrl)
                .replaceAll('pin/', '')
                .replaceAll('/', '');
          } catch (err) {
            //TODO: ignore error
            id = regexId
                .stringMatch(document
                    .querySelector('[name="og:url"]')
                    ?.attributes["content"])
                .replaceAll('pin/', '')
                .replaceAll('/', '');
          }

          print(videoLink);
          print(imageLink);
          if (videoLink != null)
            videoLink = videoLink.replaceAll('V_720P":{"url":"', '');

          fileName = "pinterest_" + id;

          if (videoLink != null) {
            // if is video

            fileName += '.mp4';

            isVideo = true;
            largeVideo = videoLink;
            _controller = VideoPlayerController.network(videoLink);
            _controller.setLooping(true);
            _controller.setVolume(0);
            await _controller.initialize();
            setState(() {
              showDownload = true;
              loading = false;
              videoMuted = true;
            });
            await _controller.play();
          } else if (imageLink != null) {
            // if is image

            fileName += '.jpeg';

            isVideo = false;
            largeImage = imageLink;
            setState(() {
              showDownload = true;
              loading = false;
              videoMuted = true;
            });
          } else {
            DownloaderService.showSnackbar(
                _scaffoldKey.currentState, "Invalid link!");
            setState(() {
              showDownload = false;
              loading = false;
              videoMuted = true;
            });
            return;
          }
          AdManager.tryPreloadInterstitial();

          ///   //s.exec(document.body.innerText)[0]
          /// /(V_720P":{"url":")(.+?)mp4/s.exec(document.body.innerText)[0]

        } else {
          DownloaderService.showSnackbar(
              _scaffoldKey.currentState, "Invalid link!");
          setState(() {
            showDownload = false;
            loading = false;
            videoMuted = true;
          });
          getIt<SentryClient>().captureException(
            exception: PintrestEx("Pintrest 404"),
            stackTrace: myController.text.trim(),
          );
        }
      }).catchError((error, stackTrace) async {
        DownloaderService.showSnackbar(
            _scaffoldKey.currentState, "There was a network error, try again.");
        setState(() {
          showDownload = false;
          loading = false;
          videoMuted = true;
        });

        await getIt<SentryClient>().captureException(
          exception: error,
          stackTrace: stackTrace,
        );
      }, test: (e) => e is HandshakeException).catchError(
          (error, stackTrace) async {
        DownloaderService.showSnackbar(
            _scaffoldKey.currentState, "Oops! Something went wrong.");
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

  _startDownload() {
    DownloaderService.startDownload(
        context, isVideo ? largeVideo : largeImage, fileName);
  }
}

Future<String> readResponse(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  response.transform(utf8.decoder).listen((data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

class PintrestEx implements Exception {
  String cause;
  PintrestEx(this.cause);
}
