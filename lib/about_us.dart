import 'dart:math';

import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:store_launcher/store_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Image.asset('assets/ic_launcher.png',
                        width: 120, height: 120),
                    SizedBox(
                      height: 20,
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth:
                              max(200, MediaQuery.of(context).size.width / 2)),
                      child: Image.asset(
                        'assets/splash_text.png',
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Check out our other apps on PlayStore!",
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Card(
                      child: InkWell(
                        onTap: () {
                          try {
                            StoreLauncher.openWithStore('id.tfn.code.myscanner')
                                .catchError((e) {
                              print('ERROR> $e');
                            });
                          } on Exception catch (e) {
                            print('$e');
                          }
                        },
                        child: ListTile(
                          leading: Image.asset('assets/myscanner.png'),
                          title: Text("My Scanner | Create PDF Easily"),
                          subtitle: Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Card(
                      child: InkWell(
                        onTap: () {
                          try {
                            StoreLauncher.openWithStore(
                                    'dev.shanbhag.wallart.wallart')
                                .catchError((e) {
                              print('ERROR> $e');
                            });
                          } on Exception catch (e) {
                            print('$e');
                          }
                        },
                        child: ListTile(
                          leading: Image.asset('assets/wallart.png'),
                          title: Text("WallArt | HD Wallpaper App"),
                          subtitle: Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                                Icon(Icons.star, size: 15),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Container(
                    //   margin: EdgeInsets.only(top: 20),
                    //   child: Column(
                    //     children: [
                    //       InkWell(
                    //           splashColor: Colors.grey[200],
                    //           onTap: () async {
                    //             await launch('https://www.flaticon.com/');
                    //           },
                    //           child: Text(
                    //             "Icons used from Flaticon",
                    //             textAlign: TextAlign.center,
                    //           )),
                    //       SizedBox(height: 5),
                    //       InkWell(
                    //         splashColor: Colors.grey[200],
                    //         onTap: () async {
                    //           await launch("https://www.freepik.com/");
                    //         },
                    //         child: Text("Illustrations used from Freepik",
                    //             textAlign: TextAlign.center),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: FlatButton.icon(
                          color: Colors.grey.withOpacity(0.3),
                          onPressed: () async {
                            showLicensePage(
                                context: context,
                                applicationName: "Any Downloader",
                                applicationIcon: Image.asset(
                                  'assets/ic_launcher.png',
                                  width: 68,
                                  height: 68,
                                ),
                                applicationVersion:
                                    (await PackageInfo.fromPlatform()).version);
                          },
                          icon: Icon(Icons.info),
                          label: Text(
                            "Show Licences",
                          )),
                    )
                  ],
                ),
              ),
              // Padding(
              //     padding: EdgeInsets.all(20),
              //     child: InkWell(
              //       splashColor: Colors.grey[200],
              //       onTap: () async {
              //         const url = 'https://adarshhegde.me';
              //         try {
              //           if (await canLaunch(url)) {
              //             await launch(url);
              //           } else {
              //             throw 'Could not launch $url';
              //           }
              //         } catch (err) {}
              //       },
              //       child: Text(
              //         "Developed by Adarsh Hegde",
              //         textAlign: TextAlign.center,
              //         style: TextStyle(color: Colors.grey.withOpacity(0.5)),
              //       ),
              //     )),
            ],
          ),
        ),
      )),
    );
  }
}
