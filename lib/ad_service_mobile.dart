import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Android/iOS için AdMob geçiş (interstitial) reklam servisi.
///
/// NOT: Şimdilik Google TEST reklam birimi kimlikleri. Yayına çıkarken AdMob'da
/// Vın Vın uygulaması açıp aşağıdaki id'leri gerçekleriyle değiştir.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  InterstitialAd? _interstitial;
  int _gameOverCount = 0;
  bool _initialized = false;

  static const int _interstitialEvery = 3; // her 3 oyun sonunda bir

  String get _interstitialUnit => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Android TEST (Geçiş)
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS TEST (Geçiş)

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Oyun bitince çağrılır; her [_interstitialEvery] oyunda bir geçiş reklamı
  /// gösterir (hazırsa). Reklam yoksa sessizce geçer.
  Future<void> notifyGameOverAndMaybeShow() async {
    _gameOverCount++;
    if (_gameOverCount % _interstitialEvery != 0) return;
    final ad = _interstitial;
    if (ad == null) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    await ad.show();
  }
}
