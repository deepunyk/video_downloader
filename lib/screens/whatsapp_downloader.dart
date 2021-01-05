import 'dart:async';
import 'dart:io';

import 'package:downloader_app/screens/whatsapp_preview.dart';
import 'package:downloader_app/services/downloader_service.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

var getIt = GetIt.instance;

class WhatsAppDownloader extends StatefulWidget {
  const WhatsAppDownloader({Key key}) : super(key: key);
  static const route = 'whatsapp_downloader';
  static const icon = 'assets/109-whatsapp.png';
  static const name = 'WhatsApp';

  static Future<List<FileSystemEntity>> _isolateStuff(String path) async {
    var files = (new Directory(path).listSync());

    files.sort((a, b) {
      return (a.statSync().modified.compareTo(b.statSync().modified)) * -1;
    });
    try {
      files.sort((a, b) {
        var aExt = a.path.split('.').last;
        var bExt = b.path.split('.').last;

        return aExt.compareTo(bExt) * -1;
      });
    } catch (error) {}
    return files;
  }

  @override
  _WhatsAppDownloaderState createState() => _WhatsAppDownloaderState();
}

class _WhatsAppDownloaderState extends State<WhatsAppDownloader> {
  bool _loaded = false;
  bool _permissionDenied = false;
  List<Widget> _statuses = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future _getWhatsappCache() async {
    final status = await Permission.storage.request();

    if (status.isGranted) {
      final externalDir = await ExtStorage.getExternalStorageDirectory();
      var _whatsappcacheDir =
          new Directory('$externalDir/WhatsApp/Media/.Statuses');

      if (await _whatsappcacheDir.exists()) {
        List<FileSystemEntity> files = (await compute(
            WhatsAppDownloader._isolateStuff, _whatsappcacheDir.path));

        List<Widget> _stuff = [];

        for (File file in files) {
          Widget _thing;
          bool isVideo = file.path.split('.').last == 'mp4';
          bool alreadySaved = false;
          var filename = file.path.split("/").last;

          alreadySaved = (await FlutterDownloader.loadTasksWithRawQuery(
                      query:
                          'SELECT * FROM task where file_name=\'$filename\''))
                  .length !=
              0;
          if (file.path.contains('.nomedia')) continue;
          if (isVideo) {
            final uint8list = await VideoThumbnail.thumbnailData(
              video: file.path,
              imageFormat: ImageFormat.JPEG,
              maxWidth:
                  300, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
              quality: 100,
            );
            _thing = Image.memory(uint8list, fit: BoxFit.cover);
          } else {
            _thing = Image.file(
              file,
              fit: BoxFit.cover,
            );
          }

          _stuff.add(Stack(
            fit: StackFit.expand,
            children: [
              Container(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WhatsappPreview(
                                  file: file,
                                ))).then((forceReload) {
                      print(forceReload.toString() + " MUHAHAHAH");
                      if (forceReload == true) {
                        setState(() {
                          _loaded = false;
                          _statuses = [];
                          _getWhatsappCache();
                        });
                      }
                    });
                  },
                  child: Card(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _thing,
                        if (isVideo)
                          Align(
                              alignment: Alignment.center,
                              child: Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          blurRadius: 10,
                                          color: Colors.black.withOpacity(0.12),
                                          spreadRadius: 3)
                                    ]),
                                child: Icon(
                                  Icons.play_circle_filled,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 64,
                                ),
                              ))
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: DownloadButton(
                  file: file,
                  alreadySaved: alreadySaved,
                  scaffoldKey: _scaffoldKey,
                ),
              )
            ],
          ));
        }
        if (mounted)
          setState(() {
            _statuses = _stuff;
            _loaded = true;
          });
      } else {
        print("doesnt exist");
      }
    } else {
      setState(() {
        _permissionDenied = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (mounted) _getWhatsappCache();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.lightGreen,
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Hero(
              tag: WhatsAppDownloader.route + "_icon",
              child:
                  Image.asset(WhatsAppDownloader.icon, width: 30, height: 30)),
          SizedBox(width: 10),
          Hero(
            tag: WhatsAppDownloader.route + "_name",
            transitionOnUserGestures: true,
            child: Material(
              type: MaterialType.transparency, // likely needed
              child: Container(
                child: Text(
                  WhatsAppDownloader.name,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ]),
      ),
      body: _permissionDenied
          ? Container(
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
                          Text(
                              "Please grant the permission to see the statuses!"),
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
                                          _permissionDenied = false;
                                        });
                                        _getWhatsappCache();
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
            )
          : _loaded && _statuses.length > 0
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      GridView.count(
                        // Create a grid with 2 columns. If you change the scrollDirection to
                        // horizontal, this produces 2 rows.
                        shrinkWrap: true,
                        primary: false,
                        padding: const EdgeInsets.all(1.5),
                        crossAxisCount: 2,
                        childAspectRatio: 1080 / 1920,
                        mainAxisSpacing: 1.0,
                        crossAxisSpacing: 1.0,
                        // Generate 100 widgets that display their index in the List.
                        children: _statuses,
                      ),
                      SizedBox(height: 55),
                    ],
                  ),
                )
              : _loaded && _statuses.length == 0
                  ? Center(
                      child: Text("No statuses found!"),
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
    );
  }
}

class DownloadButton extends StatefulWidget {
  DownloadButton({Key key, this.file, this.scaffoldKey, this.alreadySaved})
      : super(key: key);
  final File file;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool alreadySaved;
  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool alreadySaved = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      alreadySaved = widget.alreadySaved;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(5)),
      child: Material(
        color: Colors.black, // button color
        child: InkWell(
            splashColor: Colors.red, // inkwell color
            child: SizedBox(
                width: 38,
                height: 38,
                child: Icon(
                  alreadySaved ? Icons.check : Icons.file_download,
                  color: Colors.white,
                )),
            onTap: () {
              DownloaderService.copyWhatsappStatus(
                      widget.scaffoldKey.currentContext,
                      widget.scaffoldKey.currentState,
                      widget.file)
                  .then((result) {
                if (result != null && result == true) {
                  setState(() {
                    alreadySaved = true;
                  });
                }
              });
            }),
      ),
    );
  }
}
