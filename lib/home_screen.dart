import 'dart:ui';

import 'package:downloader_app/screens/facebook_downloader.dart';
import 'package:downloader_app/screens/instagram_downloader.dart';
import 'package:downloader_app/screens/pintrest_downloader.dart';
import 'package:downloader_app/screens/starmaker_downloader.dart';
import 'package:downloader_app/feature_recommend.dart';
import 'package:downloader_app/screens/tumblr_downloader.dart';
import 'package:downloader_app/screens/whatsapp_downloader.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key key}) : super(key: key);

  static const _apps = [
    [
      InstagramDownloader.name,
      InstagramDownloader.icon,
      InstagramDownloader.route
    ],
    [
      WhatsAppDownloader.name,
      WhatsAppDownloader.icon,
      WhatsAppDownloader.route
    ],
    [
      FacebookDownloader.name,
      FacebookDownloader.icon,
      FacebookDownloader.route
    ],
    [
      PintrestDownloader.name,
      PintrestDownloader.icon,
      PintrestDownloader.route
    ],
    [TumblrDownloader.name, TumblrDownloader.icon, TumblrDownloader.route],
    [
      StarmakerDownloader.name,
      StarmakerDownloader.icon,
      StarmakerDownloader.route
    ],
    ["Request for feature", null, FeatureRecommend.route]
  ];

  List<Widget> _loadDownloaders(context) {
    return HomeScreen._apps.map((downloader) {
      return new Container(
        // padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey.withOpacity(0.1),
        ),
        child: new Material(
          child: new InkWell(
            onTap: () {
              Navigator.pushNamed(context, downloader[2]);
            },
            child: new Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (downloader[1] != null) ...[
                    Hero(
                        tag: downloader[2] + "_icon",
                        child:
                            Image.asset(downloader[1], width: 42, height: 42)),
                    SizedBox(height: 10),
                  ],
                  Hero(
                      tag: downloader[2] + "_name",
                      transitionOnUserGestures: true,
                      child: Material(
                          type: MaterialType.transparency,
                          child: Container(child: Text(downloader[0]))))
                ],
              ),
            ),
          ),
          color: Colors.transparent,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            backgroundColor: Colors.red,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text("ANY DOWNLOADER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  )),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/4322729.jpg',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(10),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              childAspectRatio: 1,
              mainAxisSpacing: 0.0,
              crossAxisSpacing: 0.0,

              children: _loadDownloaders(context), //new Cards()
              // shrinkWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
