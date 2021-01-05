import 'dart:async';

//https://static.starmakerstudios.com/production/uploading/recordings/4222124662184777/master.mp4

import 'package:downloader_app/components/audio_control.dart';
import 'package:downloader_app/services/ad_manager.dart';
import 'package:downloader_app/services/downloader_service.dart';
import 'package:get_it/get_it.dart';
import 'package:html/parser.dart';
import 'package:sentry/sentry.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

var getIt = GetIt.instance;

class StarmakerDownloader extends StatefulWidget {
  const StarmakerDownloader({Key key}) : super(key: key);
  static const route = 'starmaker_downloader';
  static const icon = 'assets/starmaker.png';
  static const name = 'Starmaker';

  @override
  _StarmakerDownloaderState createState() => _StarmakerDownloaderState();
}

class _StarmakerDownloaderState extends State<StarmakerDownloader> {
  final myController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  VideoPlayerController _controller;

  bool loading = false;
  bool showDownload = false;

  String largeImage;
  String audioLink;

  String topText = "";
  String fileName = "";

  @override
  void dispose() {
    myController.dispose();
    if (_controller != null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (showDownload) {
          setState(() {
            showDownload = false;
          });
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
          backgroundColor: Colors.purple,
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Hero(
                tag: StarmakerDownloader.route + "_icon",
                child: Image.asset(StarmakerDownloader.icon,
                    width: 30, height: 30)),
            SizedBox(width: 10),
            Hero(
              tag: StarmakerDownloader.route + "_name",
              transitionOnUserGestures: true,
              child: Material(
                type: MaterialType.transparency, // likely needed
                child: Container(
                  child: Text(
                    StarmakerDownloader.name,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            )
          ]),
          leading: IconButton(
              icon: Icon(showDownload ? Icons.close : Icons.arrow_back),
              onPressed: () {
                if (showDownload)
                  setState(() {
                    showDownload = false;
                  });
                else
                  Navigator.pop(context);
              }),
        ),
        body: showDownload
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                      child: Text(topText,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold)),
                    ),
                    Image.network(
                      largeImage,
                      fit: BoxFit.fitWidth,
                    ),
                    AudioControl(
                      networkSrc: audioLink,
                      autostart: false,
                      colorsInverted: false,
                    ),
                    FlatButton(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        onPressed: !loading ? _startDownload : null,
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
                          labelText: "Paste starmaker share link here",
                        ),
                        onFieldSubmitted: (value) {
                          _handleSubmit(context);
                        },
                        enabled: !loading,
                        controller: myController,
                        validator: (String value) {
                          bool isValid = _tryValidate();
                          return !isValid ? 'Invalid tumblr post url' : null;
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
                      color: Colors.purple,
                      disabledColor: Colors.purple.withAlpha(150),
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

    return regExp.hasMatch(text) && (text.contains('m.starmakerstudios.com'));
  }

  void _handleSubmit(context) {
    if (_formKey.currentState.validate()) {
      setState(() {
        loading = true;
      });

      var lenk = myController.text
          .replaceAll(
              'OMG! I found an amazing singer on StarMaker, take a look now!#StarMaker #karaoke #sing',
              '')
          .trim();
      print(lenk);

      http.get(lenk, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.47 Safari/537.36'
      }).then((response) async {
        if (response.statusCode == 200) {
          var data = (response.body);
          print(data);
          var document = parse(data);

          var img = document
              .querySelector('[property="og:image"]')
              ?.attributes['content'];
          var title = "";
          try {
            title = document
                .querySelector('[property="og:title"]')
                ?.attributes['content'];
          } catch (err) {
            //TODO: Ignore error
          }
          var id = img.split('recordings/')[1].split('/')[0];

          audioLink =
              'https://static.starmakerstudios.com/production/uploading/recordings/$id/master.mp4';

          largeImage = img;
          topText = title;

          fileName = 'starmaker_' + id + '.mp3';
          AdManager.tryPreloadInterstitial();
          setState(() {
            showDownload = true;
            loading = false;
          });
        } else {
          DownloaderService.showSnackbar(
              _scaffoldKey.currentState, "Invalid Link!!!");
          setState(() {
            showDownload = false;
            loading = false;
          });
          getIt<SentryClient>().captureException(
            exception: StarmakerEx("Starmaker 404"),
            stackTrace: myController.text,
          );
        }
      }).catchError((error, stackTrace) async {
        print(error);

        DownloaderService.showSnackbar(
            _scaffoldKey.currentState, "Oops! Something went wrong.");
        setState(() {
          showDownload = false;
          loading = false;
        });

        await getIt<SentryClient>().captureException(
          exception: error,
          stackTrace: stackTrace,
        );
      });
    }
  }

  _startDownload() {
    DownloaderService.startDownload(context, audioLink, fileName);
  }
}

class StarmakerEx implements Exception {
  String cause;
  StarmakerEx(this.cause);
}
