// Platforma göre gerçek (mobil) veya boş (web/masaüstü) reklam servisini seçer.
// google_mobile_ads yalnızca Android/iOS'ta çalışır; web derlemesinde hiç
// import edilmez, böylece web build bozulmaz.
export 'ad_service_stub.dart' if (dart.library.io) 'ad_service_mobile.dart';
