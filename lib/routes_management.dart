import 'package:downloader_app/home_screen.dart';
import 'package:downloader_app/screens/facebook_downloader.dart';
import 'package:downloader_app/screens/instagram_downloader.dart';
import 'package:downloader_app/screens/pintrest_downloader.dart';
import 'package:downloader_app/screens/starmaker_downloader.dart';
import 'package:downloader_app/feature_recommend.dart';
import 'package:downloader_app/screens/tumblr_downloader.dart';
import 'package:downloader_app/screens/whatsapp_downloader.dart';
import 'package:flutter/material.dart';

class RoutesManager extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Any Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: 'homescreen',
      routes: {
        'homescreen': (context) => HomeScreen(),
        InstagramDownloader.route: (context) => InstagramDownloader(),
        WhatsAppDownloader.route: (context) => WhatsAppDownloader(),
        FacebookDownloader.route: (context) => FacebookDownloader(),
        PintrestDownloader.route: (context) => PintrestDownloader(),
        TumblrDownloader.route: (context) => TumblrDownloader(),
        StarmakerDownloader.route: (context) => StarmakerDownloader(),
        FeatureRecommend.route: (context) => FeatureRecommend(),
      },
    );
  }
}
