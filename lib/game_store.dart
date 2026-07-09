import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================ Yükseltmeler ============================

enum UpgradeKind { engine, accel, handling }

extension UpgradeKindInfo on UpgradeKind {
  String get title => switch (this) {
        UpgradeKind.engine => 'Motor',
        UpgradeKind.accel => 'Hızlanma',
        UpgradeKind.handling => 'Direksiyon',
      };

  String get desc => switch (this) {
        UpgradeKind.engine => 'Azami hız artar',
        UpgradeKind.accel => 'Gaza daha çabuk tepki',
        UpgradeKind.handling => 'Şerit değiştirme daha keskin',
      };

  IconData get icon => switch (this) {
        UpgradeKind.engine => Icons.speed,
        UpgradeKind.accel => Icons.bolt,
        UpgradeKind.handling => Icons.sports_esports,
      };

  String get _prefKey => switch (this) {
        UpgradeKind.engine => 'upg_engine',
        UpgradeKind.accel => 'upg_accel',
        UpgradeKind.handling => 'upg_handling',
      };
}

const int kMaxUpgradeLevel = 5;
int upgradeCost(int currentLevel) => 150 + currentLevel * 200;

// ============================ Kontrol ayarları ============================

enum SteerMode { gyro, buttons, wheel }

extension SteerModeInfo on SteerMode {
  String get title => switch (this) {
        SteerMode.gyro => 'Jiroskop',
        SteerMode.buttons => 'Sağ/Sol tuş',
        SteerMode.wheel => 'Direksiyon',
      };

  String get desc => switch (this) {
        SteerMode.gyro => 'Telefonu eğ',
        SteerMode.buttons => 'Ok tuşları',
        SteerMode.wheel => 'Direksiyon simidi çevir',
      };

  IconData get icon => switch (this) {
        SteerMode.gyro => Icons.screen_rotation,
        SteerMode.buttons => Icons.swap_horiz,
        SteerMode.wheel => Icons.trip_origin,
      };
}

// ============================ Araba modelleri ============================

enum BodyStyle { hatchback, sedan, coupe, sport }

class CarModel {
  const CarModel({
    required this.id,
    required this.name,
    required this.price,
    required this.defaultColor,
    required this.roof,
    required this.speedClass,
    required this.body,
  });

  final int id;
  final String name;
  final int price;
  final Color defaultColor;
  final Color roof;
  final int speedClass;
  final BodyStyle body;
}

const List<CarModel> kCars = [
  CarModel(id: 0, name: "'97 Renault Twingo", price: 0, defaultColor: Color(0xFF4CAF50), roof: Color(0xFF1B5E20), speedClass: 1, body: BodyStyle.hatchback),
  CarModel(id: 1, name: "'98 Fiat Palio", price: 900, defaultColor: Color(0xFFF57C00), roof: Color(0xFF7A3E00), speedClass: 2, body: BodyStyle.hatchback),
  CarModel(id: 2, name: "'98 Peugeot 106 GTI", price: 2200, defaultColor: Color(0xFFECECEC), roof: Color(0xFF7A0000), speedClass: 3, body: BodyStyle.hatchback),
  CarModel(id: 3, name: "'06 Opel Astra H", price: 4200, defaultColor: Color(0xFF9E9E9E), roof: Color(0xFF3A3A3A), speedClass: 3, body: BodyStyle.hatchback),
  CarModel(id: 4, name: "'11 VW Scirocco", price: 7500, defaultColor: Color(0xFFF5F5F5), roof: Color(0xFF37474F), speedClass: 4, body: BodyStyle.coupe),
  CarModel(id: 5, name: "'12 BMW F30", price: 12000, defaultColor: Color(0xFF1E88E5), roof: Color(0xFF0D3D66), speedClass: 4, body: BodyStyle.sedan),
  CarModel(id: 6, name: "'14 Mercedes W205", price: 20000, defaultColor: Color(0xFFD32F2F), roof: Color(0xFF611414), speedClass: 5, body: BodyStyle.sedan),
  CarModel(id: 7, name: "'21 Porsche 911", price: 40000, defaultColor: Color(0xFFEC407A), roof: Color(0xFF7A1E45), speedClass: 5, body: BodyStyle.sport),
];

CarModel carById(int id) =>
    kCars.firstWhere((c) => c.id == id, orElse: () => kCars.first);

// ============================ Modifiye seçenekleri ============================

class PaintOption {
  const PaintOption(this.name, this.color, this.price);
  final String name;
  final Color? color; // null => orijinal
  final int price;
}

const List<PaintOption> kPaints = [
  PaintOption('Orijinal', null, 0),
  PaintOption('Siyah', Color(0xFF1B1B1B), 500),
  PaintOption('Mat Siyah', Color(0xFF2C2C2C), 1500),
  PaintOption('Beyaz', Color(0xFFFAFAFA), 500),
  PaintOption('İnci Beyaz', Color(0xFFEDEDE4), 1800),
  PaintOption('Gümüş', Color(0xFFBDBDBD), 700),
  PaintOption('Füme', Color(0xFF546E7A), 900),
  PaintOption('Kırmızı', Color(0xFFD32F2F), 800),
  PaintOption('Bordo', Color(0xFF7B1E22), 1200),
  PaintOption('Turuncu', Color(0xFFF57C00), 1000),
  PaintOption('Sarı', Color(0xFFFDD835), 1000),
  PaintOption('Altın', Color(0xFFFFC107), 2500),
  PaintOption('Yeşil', Color(0xFF388E3C), 800),
  PaintOption('Neon Yeşil', Color(0xFF76FF03), 2200),
  PaintOption('Turkuaz', Color(0xFF00BCD4), 1400),
  PaintOption('Mavi', Color(0xFF1976D2), 800),
  PaintOption('Lacivert', Color(0xFF1A237E), 1200),
  PaintOption('Mor', Color(0xFF7B1FA2), 1200),
  PaintOption('Pembe', Color(0xFFEC407A), 1200),
  PaintOption('Şeker Pembe', Color(0xFFFF80AB), 1600),
];

class RimOption {
  const RimOption(this.name, this.spokes, this.color, this.price);
  final String name;
  final int spokes;
  final Color color;
  final int price;
}

const List<RimOption> kRims = [
  RimOption('Standart', 5, Color(0xFF9E9E9E), 0),
  RimOption('Spor', 6, Color(0xFFCFD8DC), 700),
  RimOption('Yıldız', 10, Color(0xFFB0BEC5), 1500),
  RimOption('Çift Kol', 10, Color(0xFFE0E0E0), 1800),
  RimOption('Siyah', 5, Color(0xFF2E3438), 1500),
  RimOption('Mat Siyah', 6, Color(0xFF23272A), 2000),
  RimOption('Beyaz', 5, Color(0xFFF5F5F5), 1800),
  RimOption('Bronz', 6, Color(0xFFB08D57), 2600),
  RimOption('Altın', 6, Color(0xFFFFC107), 3000),
  RimOption('Kırmızı', 5, Color(0xFFE53935), 2600),
];

class BumperOption {
  const BumperOption(this.name, this.style, this.price);
  final String name;
  final int style; // 0 std, 1 spor, 2 difüzör, 3 çift egzoz, 4 geniş difüzör
  final int price;
}

const List<BumperOption> kBumpers = [
  BumperOption('Standart', 0, 0),
  BumperOption('Spor', 1, 1200),
  BumperOption('Difüzör', 2, 2200),
  BumperOption('Çift Egzoz', 3, 2800),
  BumperOption('Yarış Difüzör', 4, 4000),
];

class SpoilerOption {
  const SpoilerOption(this.name, this.style, this.price);
  final String name;
  final int style; // 0 yok, 1 lip, 2 orta kanat, 3 GT kanat
  final int price;
}

const List<SpoilerOption> kSpoilers = [
  SpoilerOption('Yok', 0, 0),
  SpoilerOption('Lip', 1, 900),
  SpoilerOption('Orta Kanat', 2, 2000),
  SpoilerOption('GT Kanat', 3, 3800),
];

class NeonOption {
  const NeonOption(this.name, this.color, this.price);
  final String name;
  final Color? color; // null => kapalı
  final int price;
}

const List<NeonOption> kNeons = [
  NeonOption('Kapalı', null, 0),
  NeonOption('Mavi', Color(0xFF2979FF), 1500),
  NeonOption('Mor', Color(0xFFAA00FF), 1500),
  NeonOption('Pembe', Color(0xFFFF4081), 1800),
  NeonOption('Yeşil', Color(0xFF00E676), 1800),
  NeonOption('Kırmızı', Color(0xFFFF1744), 1800),
  NeonOption('Turkuaz', Color(0xFF1DE9B6), 2200),
  NeonOption('Turuncu', Color(0xFFFF9100), 2200),
];

/// Bir arabanın uygulanmış tüm modifiye seçimleri (çizim için taşınır).
class CarConfig {
  const CarConfig({
    required this.car,
    required this.paintIndex,
    required this.rimIndex,
    required this.bumperIndex,
    this.spoilerIndex = 0,
    this.neonIndex = 0,
  });

  final CarModel car;
  final int paintIndex;
  final int rimIndex;
  final int bumperIndex;
  final int spoilerIndex;
  final int neonIndex;

  Color get bodyColor => kPaints[paintIndex].color ?? car.defaultColor;
  RimOption get rim => kRims[rimIndex];
  BumperOption get bumper => kBumpers[bumperIndex];
  NeonOption get neon => kNeons[neonIndex];

  /// Seçili spoiler; hiçbiri seçili değilse spor gövde varsayılan olarak
  /// orta kanat gelir.
  int get spoilerStyle {
    if (spoilerIndex > 0) return kSpoilers[spoilerIndex].style;
    return car.body == BodyStyle.sport ? 2 : 0;
  }
}

// ============================ Kalıcı durum ============================

class GameStore extends ChangeNotifier {
  GameStore._();
  static final GameStore instance = GameStore._();

  static const _kMoney = 'money';
  static const _kBest = 'best_distance';
  static const _kOwned = 'owned_cars';
  static const _kSelected = 'selected_car';
  static const _kSound = 'sound_on';
  static const _kSteerMode = 'steer_mode';
  static const _kGasRight = 'gas_on_right';

  late SharedPreferences _prefs;
  bool _loaded = false;
  bool get loaded => _loaded;

  int _money = 0;
  int _bestDistance = 0;
  Set<int> _ownedCars = {0};
  int _selectedCar = 0;
  bool _soundOn = true;
  SteerMode _steerMode = SteerMode.buttons;
  bool _gasOnRight = true;

  // Modifiye: her tür için (owned seti, seçim haritası, prefs anahtarları).
  late final _ModDim _paints =
      _ModDim('owned_paints', 'car_paint', kPaints.length);
  late final _ModDim _rims = _ModDim('owned_rims', 'car_rim', kRims.length);
  late final _ModDim _bumpers =
      _ModDim('owned_bumpers', 'car_bumper', kBumpers.length);
  late final _ModDim _spoilers =
      _ModDim('owned_spoilers', 'car_spoiler', kSpoilers.length);
  late final _ModDim _neons = _ModDim('owned_neons', 'car_neon', kNeons.length);

  final Map<UpgradeKind, int> _upgrades = {
    for (final k in UpgradeKind.values) k: 0,
  };

  // ---- getter'lar ----
  int get money => _money;
  int get bestDistance => _bestDistance;
  int get selectedCar => _selectedCar;
  bool get soundOn => _soundOn;
  SteerMode get steerMode => _steerMode;
  bool get gasOnRight => _gasOnRight;

  bool isCarOwned(int id) => _ownedCars.contains(id);

  int upgradeLevel(UpgradeKind k) => _upgrades[k] ?? 0;
  double upgradeFactor(UpgradeKind k) => upgradeLevel(k) / kMaxUpgradeLevel;

  CarModel get selectedCarModel => carById(_selectedCar);

  CarConfig configFor(int carId) => CarConfig(
        car: carById(carId),
        paintIndex: _paints.get(carId),
        rimIndex: _rims.get(carId),
        bumperIndex: _bumpers.get(carId),
        spoilerIndex: _spoilers.get(carId),
        neonIndex: _neons.get(carId),
      );

  CarConfig get selectedConfig => configFor(_selectedCar);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _money = _prefs.getInt(_kMoney) ?? 0;
    _bestDistance = _prefs.getInt(_kBest) ?? 0;
    _ownedCars = _readIntSet(_kOwned, {0});
    _selectedCar = _prefs.getInt(_kSelected) ?? 0;
    _soundOn = _prefs.getBool(_kSound) ?? true;
    _steerMode = SteerMode.values[(_prefs.getInt(_kSteerMode) ?? 1)
        .clamp(0, SteerMode.values.length - 1)];
    _gasOnRight = _prefs.getBool(_kGasRight) ?? true;

    for (final d in _dims) {
      d.load(_prefs);
    }
    for (final k in UpgradeKind.values) {
      _upgrades[k] = (_prefs.getInt(k._prefKey) ?? 0).clamp(0, kMaxUpgradeLevel);
    }
    _loaded = true;
    notifyListeners();
  }

  List<_ModDim> get _dims => [_paints, _rims, _bumpers, _spoilers, _neons];

  // ---- prefs yardımcı ----
  Set<int> _readIntSet(String key, Set<int> fallback) {
    final list = _prefs.getStringList(key);
    if (list == null) return {...fallback};
    return list.map(int.parse).toSet()..addAll(fallback);
  }

  Future<void> _writeIntSet(String key, Set<int> set) =>
      _prefs.setStringList(key, set.map((e) => e.toString()).toList());

  // ---- oyun sonu ----
  Future<int> registerRun({required int distance, required int coins}) async {
    final earned = coins + distance ~/ 10;
    _money += earned;
    await _prefs.setInt(_kMoney, _money);
    if (distance > _bestDistance) {
      _bestDistance = distance;
      await _prefs.setInt(_kBest, _bestDistance);
    }
    notifyListeners();
    return earned;
  }

  // ---- araba ----
  Future<bool> buyCar(int id) async {
    final car = carById(id);
    if (_ownedCars.contains(id) || _money < car.price) return false;
    _money -= car.price;
    _ownedCars.add(id);
    await _prefs.setInt(_kMoney, _money);
    await _writeIntSet(_kOwned, _ownedCars);
    notifyListeners();
    return true;
  }

  Future<void> selectCar(int id) async {
    if (!_ownedCars.contains(id)) return;
    _selectedCar = id;
    await _prefs.setInt(_kSelected, id);
    notifyListeners();
  }

  // ---- yükseltme ----
  Future<bool> buyUpgrade(UpgradeKind k) async {
    final level = upgradeLevel(k);
    if (level >= kMaxUpgradeLevel) return false;
    final cost = upgradeCost(level);
    if (_money < cost) return false;
    _money -= cost;
    _upgrades[k] = level + 1;
    await _prefs.setInt(_kMoney, _money);
    await _prefs.setInt(k._prefKey, level + 1);
    notifyListeners();
    return true;
  }

  // ---- modifiye (genel) ----
  bool _isOwned(_ModDim d, int i) => d.owned.contains(i);
  int _applied(_ModDim d, int carId) => d.get(carId);

  Future<bool> _buy(_ModDim d, int i, int price) async {
    if (d.owned.contains(i) || _money < price) return false;
    _money -= price;
    d.owned.add(i);
    await _prefs.setInt(_kMoney, _money);
    await _writeIntSet(d.ownedKey, d.owned);
    notifyListeners();
    return true;
  }

  Future<void> _apply(_ModDim d, int carId, int i) async {
    if (!d.owned.contains(i)) return;
    d.selection[carId] = i;
    await d.saveSelection(_prefs);
    notifyListeners();
  }

  // Boya
  bool isPaintOwned(int i) => _isOwned(_paints, i);
  int carPaint(int id) => _applied(_paints, id);
  Future<bool> buyPaint(int i) => _buy(_paints, i, kPaints[i].price);
  Future<void> applyPaint(int carId, int i) => _apply(_paints, carId, i);

  // Jant
  bool isRimOwned(int i) => _isOwned(_rims, i);
  int carRim(int id) => _applied(_rims, id);
  Future<bool> buyRim(int i) => _buy(_rims, i, kRims[i].price);
  Future<void> applyRim(int carId, int i) => _apply(_rims, carId, i);

  // Tampon
  bool isBumperOwned(int i) => _isOwned(_bumpers, i);
  int carBumper(int id) => _applied(_bumpers, id);
  Future<bool> buyBumper(int i) => _buy(_bumpers, i, kBumpers[i].price);
  Future<void> applyBumper(int carId, int i) => _apply(_bumpers, carId, i);

  // Kanat
  bool isSpoilerOwned(int i) => _isOwned(_spoilers, i);
  int carSpoiler(int id) => _applied(_spoilers, id);
  Future<bool> buySpoiler(int i) => _buy(_spoilers, i, kSpoilers[i].price);
  Future<void> applySpoiler(int carId, int i) => _apply(_spoilers, carId, i);

  // Neon
  bool isNeonOwned(int i) => _isOwned(_neons, i);
  int carNeon(int id) => _applied(_neons, id);
  Future<bool> buyNeon(int i) => _buy(_neons, i, kNeons[i].price);
  Future<void> applyNeon(int carId, int i) => _apply(_neons, carId, i);

  // ---- ayarlar ----
  Future<void> setSoundOn(bool v) async {
    _soundOn = v;
    await _prefs.setBool(_kSound, v);
    notifyListeners();
  }

  Future<void> setSteerMode(SteerMode m) async {
    _steerMode = m;
    await _prefs.setInt(_kSteerMode, m.index);
    notifyListeners();
  }

  Future<void> setGasOnRight(bool v) async {
    _gasOnRight = v;
    await _prefs.setBool(_kGasRight, v);
    notifyListeners();
  }

  Future<void> addMoney(int amount) async {
    _money += amount;
    await _prefs.setInt(_kMoney, _money);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _prefs.clear();
    _money = 0;
    _bestDistance = 0;
    _ownedCars = {0};
    _selectedCar = 0;
    _soundOn = true;
    _steerMode = SteerMode.buttons;
    _gasOnRight = true;
    for (final d in _dims) {
      d.reset();
    }
    for (final k in UpgradeKind.values) {
      _upgrades[k] = 0;
    }
    notifyListeners();
  }
}

/// Bir modifiye türü için sahiplik + araba-başı seçim durumu.
class _ModDim {
  _ModDim(this.ownedKey, this.selectionKey, this.count);
  final String ownedKey;
  final String selectionKey;
  final int count;

  Set<int> owned = {0};
  final Map<int, int> selection = {};

  int get(int carId) => selection[carId] ?? 0;

  void load(SharedPreferences prefs) {
    final list = prefs.getStringList(ownedKey);
    owned = list == null ? {0} : (list.map(int.parse).toSet()..add(0));
    selection.clear();
    for (final e in prefs.getStringList(selectionKey) ?? const <String>[]) {
      final p = e.split(':');
      if (p.length == 2) {
        final v = int.parse(p[1]);
        if (v >= 0 && v < count) selection[int.parse(p[0])] = v;
      }
    }
  }

  Future<void> saveSelection(SharedPreferences prefs) => prefs.setStringList(
      selectionKey,
      selection.entries.map((e) => '${e.key}:${e.value}').toList());

  void reset() {
    owned = {0};
    selection.clear();
  }
}
