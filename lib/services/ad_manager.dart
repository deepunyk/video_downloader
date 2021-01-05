import 'package:firebase_admob/firebase_admob.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry/sentry.dart';

var getIt = GetIt.instance;

bool testing = false;
const testDevice = "ECDBBB6F14BDA02E19E0C01599DEF105";

class AdManager {
  static InterstitialAd _interstitialAd;
  static InterstitialAd _interstitialAdPreloaded;
  static BannerAd _bannerAd;
  static int tries = 1;
  static bool bannershown = false;
  static String get appId {
    if (testing)
      return "ca-app-pub-3940256099942544~4354546703";
    else
      return "ca-app-pub-3691525575191501~8319108067";
  }

  static String get bannerAdUnitId {
    if (testing)
      return "ca-app-pub-3940256099942544/8865242552";
    else
      return "ca-app-pub-3691525575191501/9446333386";
  }

  static String get interstitialAdUnitId {
    if (testing)
      return "ca-app-pub-3940256099942544/7049598008";
    else
      return "ca-app-pub-3691525575191501/1152910393";
  }

  static _createInterstitialAd() {
    return InterstitialAd(
        adUnitId: interstitialAdUnitId,
        //Change Interstitial AdUnitId with Admob ID
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          print("IntersttialAd $event");
        });
  }

  static Future<dynamic> showInstantInterstitialAd() async {
    try {
      _interstitialAd = _createInterstitialAd();

      await _interstitialAd.load();

      await _interstitialAd.show();
      _interstitialAd.dispose();
      _interstitialAd = null;
    } catch (err, stackTrace) {
      await getIt<SentryClient>().captureException(
        exception: err,
        stackTrace: stackTrace,
      );
    }
  }

  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
    testDevices: <String>[testDevice],
    keywords: <String>[
      'status downloader',
      'status whatsapp',
      'downloader',
      'video download',
      'downloader'
    ],
    childDirected: true,
  );

  //////////////// BANNER AD ////////////

  static _createBannerAd() {
    return BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        targetingInfo: targetingInfo,
        listener: (MobileAdEvent event) {
          switch (event) {
            case MobileAdEvent.loaded:
              //  Handle this case.
              bannershown = true;
              break;
            case MobileAdEvent.failedToLoad:
              print("FAILED TO LOAD");
              bannershown = false;

              if (tries <= 5) {
                Future.delayed(Duration(seconds: 5 * tries)).then((value) {
                  loadBannerAd();
                  tries++;
                });
              }
              break;
            case MobileAdEvent.clicked:
              //  Handle this case.
              break;
            case MobileAdEvent.impression:
              //  Handle this case.
              break;
            case MobileAdEvent.opened:
              //  Handle this case.
              break;
            case MobileAdEvent.leftApplication:
              //  Handle this case.
              break;
            case MobileAdEvent.closed:
              //  Handle this case.
              break;
          }
        });
  }

  static void loadBannerAd() async {
    if (_bannerAd == null || !await _bannerAd.isLoaded()) {
      _bannerAd?.dispose();
      _bannerAd = _createBannerAd();
      await _bannerAd.load();
      await _bannerAd.show(anchorType: AnchorType.bottom, anchorOffset: 55);
    }
  }

  static void tryPreloadInterstitial() async {
    try {
      print("TRYING TO PRELOAD AD!!!!");
      if (_interstitialAdPreloaded == null ||
          !await _interstitialAdPreloaded.isLoaded()) {
        _interstitialAdPreloaded = _createInterstitialAd();
        await _interstitialAdPreloaded.load();
        await _interstitialAdPreloaded?.dispose();
        _interstitialAdPreloaded = null;
      }
    } catch (err, stackTrace) {
      if (_interstitialAdPreloaded != null) {
        _interstitialAdPreloaded?.dispose();
        _interstitialAdPreloaded = null;
      }
      await getIt<SentryClient>().captureException(
        exception: err,
        stackTrace: stackTrace,
      );
    }
  }

  static void tryShowPreloadedInterstitial() async {
    try {
      if (_interstitialAdPreloaded != null &&
          await _interstitialAdPreloaded?.isLoaded()) {
        await _interstitialAdPreloaded?.show();
        _interstitialAdPreloaded?.dispose();
        _interstitialAdPreloaded = null;
      } else {
        showInstantInterstitialAd();
      }
    } catch (err, stackTrace) {
      await getIt<SentryClient>().captureException(
        exception: err,
        stackTrace: stackTrace,
      );
      showInstantInterstitialAd();
    }
  }
}
