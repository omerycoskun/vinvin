using UnityEngine;

namespace VinVin
{
    /// <summary>Oyuncunun seçebileceği araç.</summary>
    public sealed class PlayerCarDef
    {
        public readonly string Model;      // Resources/Cars/<Model>.fbx
        public readonly string Name;
        public readonly int Price;
        public readonly float MaxKmh;
        public readonly float Accel;       // km/h / s
        public readonly float Handling;    // yanal hız (m/s)
        public readonly float Length;      // metre (görsel ölçek)

        public PlayerCarDef(string model, string name, int price, float maxKmh, float accel, float handling, float length)
        {
            Model = model; Name = name; Price = price; MaxKmh = maxKmh; Accel = accel; Handling = handling; Length = length;
        }
    }

    /// <summary>Trafikteki araç tipi.</summary>
    public sealed class TrafficDef
    {
        public readonly string Model;
        public readonly float Length;
        public readonly float Weight;      // seçilme ağırlığı
        public readonly bool Tintable;

        public TrafficDef(string model, float length, float weight, bool tintable)
        {
            Model = model; Length = length; Weight = weight; Tintable = tintable;
        }
    }

    /// <summary>Oyun verileri. Model dosyaları Kenney "Car Kit" (CC0) paketinden.</summary>
    public static class Catalog
    {
        public static readonly PlayerCarDef[] PlayerCars =
        {
            new PlayerCarDef("hatchback-sports", "Minik",   0,    170, 26, 7.0f, 4.0f),
            new PlayerCarDef("sedan",            "Şehirli", 600,  185, 28, 7.2f, 4.5f),
            new PlayerCarDef("suv-luxury",       "Dağcı",   1500, 200, 30, 6.8f, 4.8f),
            new PlayerCarDef("sedan-sports",     "Rüzgar",  3000, 230, 36, 8.0f, 4.6f),
            new PlayerCarDef("race",             "Şimşek",  6000, 270, 44, 9.0f, 4.4f),
            new PlayerCarDef("race-future",      "Gelecek", 10000, 310, 52, 9.6f, 4.6f),
        };

        public static readonly TrafficDef[] Traffic =
        {
            new TrafficDef("sedan",         4.5f,  6, true),
            new TrafficDef("suv",           4.7f,  5, true),
            new TrafficDef("hatchback-sports", 4.0f, 4, true),
            new TrafficDef("taxi",          4.5f,  3, false),
            new TrafficDef("van",           5.2f,  3, true),
            new TrafficDef("delivery",      6.0f,  2, false),
            new TrafficDef("truck",         7.5f,  2, true),
            new TrafficDef("police",        4.6f,  1, false),
            new TrafficDef("ambulance",     6.0f,  1, false),
            new TrafficDef("garbage-truck", 8.0f,  1, false),
            new TrafficDef("firetruck",     8.5f,  0.6f, false),
        };

        /// <summary>Boya renkleri (model dokusunun üstüne çarpılır; beyaz = orijinal).</summary>
        public static readonly Color[] Paints =
        {
            Color.white,
            new Color(1.00f, 0.45f, 0.40f),
            new Color(0.45f, 0.70f, 1.00f),
            new Color(0.55f, 1.00f, 0.55f),
            new Color(1.00f, 0.90f, 0.35f),
            new Color(0.80f, 0.55f, 1.00f),
            new Color(1.00f, 0.60f, 0.20f),
            new Color(0.45f, 0.45f, 0.50f),
        };

        public const int PaintPrice = 150;

        public static TrafficDef PickTraffic(System.Random rng)
        {
            float total = 0;
            foreach (var t in Traffic) total += t.Weight;
            var pick = (float)rng.NextDouble() * total;
            foreach (var t in Traffic)
            {
                pick -= t.Weight;
                if (pick <= 0) return t;
            }
            return Traffic[0];
        }
    }

    /// <summary>Kalıcı oyuncu verisi (PlayerPrefs).</summary>
    public static class Save
    {
        public static int Coins { get => PlayerPrefs.GetInt("coins", 0); set { PlayerPrefs.SetInt("coins", value); PlayerPrefs.Save(); } }
        public static int Best { get => PlayerPrefs.GetInt("best", 0); set { PlayerPrefs.SetInt("best", value); PlayerPrefs.Save(); } }
        public static int SelectedCar { get => Mathf.Clamp(PlayerPrefs.GetInt("car", 0), 0, Catalog.PlayerCars.Length - 1); set { PlayerPrefs.SetInt("car", value); PlayerPrefs.Save(); } }
        public static bool TiltControl { get => PlayerPrefs.GetInt("tilt", 0) == 1; set { PlayerPrefs.SetInt("tilt", value ? 1 : 0); PlayerPrefs.Save(); } }
        public static bool Sound { get => PlayerPrefs.GetInt("sound", 1) == 1; set { PlayerPrefs.SetInt("sound", value ? 1 : 0); PlayerPrefs.Save(); } }

        public static bool IsUnlocked(int car) => car == 0 || PlayerPrefs.GetInt("unlock_" + car, 0) == 1;
        public static void Unlock(int car) { PlayerPrefs.SetInt("unlock_" + car, 1); PlayerPrefs.Save(); }

        public static int Paint(int car) => Mathf.Clamp(PlayerPrefs.GetInt("paint_" + car, 0), 0, Catalog.Paints.Length - 1);
        public static void SetPaint(int car, int paint) { PlayerPrefs.SetInt("paint_" + car, paint); PlayerPrefs.Save(); }
    }
}
