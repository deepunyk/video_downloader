import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:downloader_app/about_us.dart';
import 'package:downloader_app/downloads_screen.dart';
import 'package:downloader_app/routes_management.dart';
import 'package:downloader_app/services/ad_manager.dart';
import 'package:downloader_app/services/download_progress_broadcast.dart';
import 'package:downloader_app/update_screen.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:custom_navigator/custom_navigator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:sentry/sentry.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  getIt.registerSingleton<DownloadProgressBroadcast>(
      DownloadProgressBroadcast());

  getIt.registerSingleton<SentryClient>(SentryClient(
      dsn:
          "https://d6e082c049d34a5c963d5babc6c4f27c@o458193.ingest.sentry.io/5455298"));

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['Icons8'], '''
    Illustrations used from Icons8 pack
    https://icons8.com/illustrations/empty
    ''');
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['DrawKit'], '''
    Illustrations used from DrawKit - Grape Pack
    https://www.drawkit.io/product/grape-illustration-pack
    ''');
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['FlatIcon'], '''
    Illustrations used from FlatIcon
    https://www.flaticon.com/
    ''');
  });
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['DrawKit'], '''
    Illustrations used from Freepik
    https://www.freepik.com/
    ''');
  });

  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );

  runZonedGuarded(
    () => runApp(MyApp()),
    (error, stackTrace) async {
      await getIt<SentryClient>().captureException(
        exception: error,
        stackTrace: stackTrace,
      );
    },
  );
}

//give a navigator key to [MaterialApp] if you want to use the default navigation
//anywhere in your app eg: line 15 & line 93
GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      navigatorKey: mainNavigatorKey,
      title: 'Any Downloader',
      theme: ThemeData(
          splashFactory: InkRipple.splashFactory, primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool granted = false;
  BannerAd _bannerAd;

  ReceivePort _receivePort = ReceivePort();

  Future<void> _initAdMob() {
    return FirebaseAdMob.instance.initialize(appId: AdManager.appId);
  }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////

  static downloadingCallback(id, status, progress) {
    ///Looking up for a send port
    SendPort sendPort = IsolateNameServer.lookupPortByName("downloading");

    ///ssending the data
    sendPort.send([id, status, progress]);
  }

  @override
  void initState() {
    super.initState();

    //////////////////////////////////
    _initAdMob();

    AdManager.loadBannerAd();

    ///////////////

    IsolateNameServer.registerPortWithName(
        _receivePort.sendPort, "downloading");

    _receivePort.listen((message) {
      getIt<DownloadProgressBroadcast>().addIntoSink(message);
      DownloadTaskStatus status = message[1];
      if (status.value == 3) {
        AdManager.tryShowPreloadedInterstitial();
      }
    });
    FlutterDownloader.registerCallback(downloadingCallback);

    // Check for updates

    // _checkUpdates();
  }

  _checkUpdates() async {
    InAppUpdate.checkForUpdate().then((info) {
      if (info.updateAvailable == true) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UpdateScreen(),
              fullscreenDialog: true,
            ));
      }
    }).catchError((error, stackTrace) {
      getIt<SentryClient>().captureException(
        exception: error,
        stackTrace: stackTrace,
      );
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();

    super.dispose();
  }

  List<Widget> _pages = [RoutesManager(), DownloadsPage(), AboutPage()];
  int _currentIndex = 0;
  int _previousIndex = 0;

  // Custom navigator takes a global key if you want to access the
  // navigator from outside it's widget tree subtree
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: _items,
        onTap: (index) {
          navigatorKey.currentState.maybePop();
          Navigator.maybePop(context);
          _previousIndex = _currentIndex;
          setState(() {
            _currentIndex = index;
          });
        },
        currentIndex: _currentIndex,
      ),
      body: CustomNavigator(
        navigatorKey: navigatorKey,
        home: PageTransitionSwitcher(
          reverse: _currentIndex < _previousIndex,
          child: _pages[_currentIndex],
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
        ),
        //Specify your page route [PageRoutes.materialPageRoute] or [PageRoutes.cupertinoPageRoute]
        pageRoute: PageRoutes.materialPageRoute,
      ),
    );
  }

  final _items = [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
    BottomNavigationBarItem(
        icon: StreamBuilder(
          initialData: 0,
          stream: getIt<DownloadProgressBroadcast>().newDownloadCountStream,
          builder: (_, snapshot) => BadgeIcon(
            icon: Icon(Icons.save_alt, size: 25),
            badgeCount: snapshot.data,
          ),
        ),
        label: "Downloads"),
    BottomNavigationBarItem(
      icon: Icon(Icons.info),
      label: 'About App',
    ),
  ];
}

class BadgeIcon extends StatelessWidget {
  BadgeIcon(
      {this.icon,
      this.badgeCount = 0,
      this.showIfZero = false,
      this.badgeColor = Colors.red,
      TextStyle badgeTextStyle})
      : this.badgeTextStyle = badgeTextStyle ??
            TextStyle(
              color: Colors.white,
              fontSize: 8,
              height: 1,
            );
  final Widget icon;
  final int badgeCount;
  final bool showIfZero;
  final Color badgeColor;
  final TextStyle badgeTextStyle;

  @override
  Widget build(BuildContext context) {
    return new Stack(children: <Widget>[
      icon,
      if (badgeCount > 0 || showIfZero) badge(badgeCount),
    ]);
  }

  Widget badge(int count) => Positioned(
        right: 0,
        top: 0,
        child: new Container(
          padding: EdgeInsets.all(1),
          decoration: new BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(8.5),
          ),
          constraints: BoxConstraints(
            minWidth: 15,
            minHeight: 15,
          ),
          child: Text(
            count.toString(),
            style: new TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
}
