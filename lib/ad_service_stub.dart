/// Reklam desteklemeyen platformlar (web/masaüstü) için boş servis.
class AdService {
  static final AdService instance = AdService._();
  AdService._();

  Future<void> initialize() async {}

  /// Oyun bitti; gerekiyorsa geçiş reklamı gösterir (web'de no-op).
  Future<void> notifyGameOverAndMaybeShow() async {}
}
