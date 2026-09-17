using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace VinVin
{
    /// <summary>Tüm ekranlar: menü, garaj, gösterge + kontroller, duraklatma, oyun sonu.</summary>
    public sealed class RaceUI
    {
        static readonly Color Orange = new Color(1.00f, 0.55f, 0.15f);
        static readonly Color Blue = new Color(0.20f, 0.52f, 0.95f);
        static readonly Color Green = new Color(0.22f, 0.72f, 0.38f);
        static readonly Color Red = new Color(0.90f, 0.25f, 0.25f);
        static readonly Color Dark = new Color(0.07f, 0.09f, 0.14f, 0.82f);
        static readonly Color Glass = new Color(0.07f, 0.09f, 0.14f, 0.45f);
        static readonly Color Gold = new Color(1.00f, 0.80f, 0.20f);

        readonly GameManager game;
        readonly Canvas canvas;
        readonly RectTransform menu, garage, hud, pause, over;
        readonly List<RectTransform> screens = new List<RectTransform>();

        // Menü
        Text menuCoins, menuBest, menuCar;
        Button controlToggle, soundToggle;

        // Garaj
        Text garageName, garageCoins, garagePrice;
        Image barSpeed, barAccel, barHandling;
        Button garageAction;
        readonly List<Image> swatches = new List<Image>();

        // HUD
        Text hudScore, hudSpeed, hudDistance, popup, toast;
        HoldButton gas, brake, left, right;
        RectTransform steerButtons;
        float popupTimer, toastTimer;

        // Oyun sonu
        Text overTitle, overScore, overBest, overCoins, overStats;

        public RaceUI(GameManager game, Transform parent)
        {
            this.game = game;
            canvas = UiKit.CreateCanvas(parent);
            var root = canvas.transform;

            menu = MakeScreen("Menu", root); BuildMenu();
            garage = MakeScreen("Garage", root); BuildGarage();
            hud = MakeScreen("Hud", root); BuildHud();
            pause = MakeScreen("Pause", root); BuildPause();
            over = MakeScreen("GameOver", root); BuildGameOver();

            popup = UiKit.Label(root, "", 64, new Vector2(0.5f, 0.68f), Vector2.zero, new Vector2(1200, 100), color: Gold);
            toast = UiKit.Label(root, "", 44, new Vector2(0.5f, 0.12f), Vector2.zero, new Vector2(1400, 80));
            var ticker = canvas.gameObject.AddComponent<UiTicker>();
            ticker.OnTick = Tick;
        }

        RectTransform MakeScreen(string name, Transform parent)
        {
            var rt = UiKit.Stretch(name, parent);
            rt.gameObject.SetActive(false);
            screens.Add(rt);
            return rt;
        }

        void Show(RectTransform s)
        {
            foreach (var x in screens) x.gameObject.SetActive(x == s);
        }

        void Tick(float dt)
        {
            if (popupTimer > 0)
            {
                popupTimer -= dt;
                float a = Mathf.Clamp01(popupTimer / 0.3f);
                popup.color = new Color(Gold.r, Gold.g, Gold.b, a);
                popup.rectTransform.localScale = Vector3.one * (1f + (1f - Mathf.Clamp01((1.1f - popupTimer) / 0.15f)) * 0.3f);
            }
            else popup.text = "";

            if (toastTimer > 0) toastTimer -= dt; else toast.text = "";
        }

        // ------------------------------------------------------------------ Menü

        void BuildMenu()
        {
            var t = menu.transform;
            var shade = UiKit.Fill(t, new Color(0, 0, 0, 0.18f));
            shade.raycastTarget = false;

            UiKit.Label(t, "VIN VIN", 170, new Vector2(0.28f, 0.72f), Vector2.zero, new Vector2(900, 220), color: Orange);
            UiKit.Label(t, "3D OTOYOL", 58, new Vector2(0.28f, 0.58f), Vector2.zero, new Vector2(900, 80));

            menuCoins = UiKit.Label(t, "", 50, new Vector2(1, 1), new Vector2(-220, -70), new Vector2(400, 70), TextAnchor.MiddleRight, Gold);
            menuBest = UiKit.Label(t, "", 46, new Vector2(0.28f, 0.47f), Vector2.zero, new Vector2(900, 70));
            menuCar = UiKit.Label(t, "", 40, new Vector2(0.28f, 0.40f), Vector2.zero, new Vector2(900, 60), color: new Color(1, 1, 1, 0.85f));

            UiKit.Button(t, "BAŞLA", new Vector2(0.28f, 0.25f), Vector2.zero, new Vector2(520, 150), Orange, game.StartRun, 72);
            UiKit.Button(t, "GARAJ", new Vector2(0.28f, 0.09f), new Vector2(-135, 0), new Vector2(250, 110), Blue, game.ShowGarage, 46);
            controlToggle = UiKit.Button(t, "", new Vector2(0.28f, 0.09f), new Vector2(135, 0), new Vector2(250, 110), Glass, () =>
            {
                Save.TiltControl = !Save.TiltControl;
                RefreshMenu();
            }, 36);
            soundToggle = UiKit.Button(t, "", new Vector2(1, 0), new Vector2(-150, 90), new Vector2(220, 100), Glass, () =>
            {
                Save.Sound = !Save.Sound;
                RefreshMenu();
            }, 36);
        }

        void RefreshMenu()
        {
            menuCoins.text = "ALTIN  " + Save.Coins;
            menuBest.text = "REKOR  " + Save.Best;
            menuCar.text = "Araç: " + Catalog.PlayerCars[Save.SelectedCar].Name;
            UiKit.SetText(controlToggle, Save.TiltControl ? "Kontrol: EĞİM" : "Kontrol: TUŞ");
            UiKit.SetText(soundToggle, Save.Sound ? "Ses: AÇIK" : "Ses: KAPALI");
        }

        public void ShowMenu()
        {
            RefreshMenu();
            Show(menu);
        }

        // ------------------------------------------------------------------ Garaj

        void BuildGarage()
        {
            var t = garage.transform;
            UiKit.Button(t, "‹ GERİ", new Vector2(0, 1), new Vector2(150, -80), new Vector2(240, 100), Glass, game.CloseGarage, 42);
            garageCoins = UiKit.Label(t, "", 50, new Vector2(1, 1), new Vector2(-220, -70), new Vector2(400, 70), TextAnchor.MiddleRight, Gold);

            var panel = UiKit.Panel(t, new Vector2(1, 0.5f), new Vector2(-360, -40), new Vector2(620, 760), Dark).transform;
            garageName = UiKit.Label(panel, "", 76, new Vector2(0.5f, 1), new Vector2(0, -80), new Vector2(560, 100), color: Orange);
            barSpeed = Bar(panel, "HIZ", -190);
            barAccel = Bar(panel, "HIZLANMA", -270);
            barHandling = Bar(panel, "YOL TUTUŞ", -350);

            UiKit.Label(panel, "BOYA (" + Catalog.PaintPrice + " altın)", 34, new Vector2(0.5f, 1), new Vector2(0, -440), new Vector2(560, 50));
            for (int i = 0; i < Catalog.Paints.Length; i++)
            {
                int idx = i;
                float x = -210 + (i % 4) * 140;
                float y = -520 - (i / 4) * 110;
                var b = UiKit.Button(panel, "", new Vector2(0.5f, 1), new Vector2(x, y), new Vector2(110, 90), Catalog.Paints[i], () => game.GaragePaint(idx));
                swatches.Add(b.GetComponent<Image>());
            }

            garagePrice = UiKit.Label(t, "", 44, new Vector2(0.5f, 0), new Vector2(0, 250), new Vector2(800, 70), color: Gold);
            UiKit.Button(t, "‹", new Vector2(0.5f, 0), new Vector2(-520, 120), new Vector2(150, 150), Glass, () => game.GarageBrowse(-1), 90);
            UiKit.Button(t, "›", new Vector2(0.5f, 0), new Vector2(-100, 120), new Vector2(150, 150), Glass, () => game.GarageBrowse(1), 90);
            garageAction = UiKit.Button(t, "", new Vector2(0.5f, 0), new Vector2(-310, 120), new Vector2(240, 150), Green, game.GarageSelectOrBuy, 44);
        }

        Image Bar(Transform panel, string label, float y)
        {
            UiKit.Label(panel, label, 32, new Vector2(0.5f, 1), new Vector2(-150, y), new Vector2(240, 50), TextAnchor.MiddleLeft);
            var bg = UiKit.Panel(panel, new Vector2(0.5f, 1), new Vector2(120, y), new Vector2(300, 30), new Color(1, 1, 1, 0.15f));
            var fill = UiKit.Panel(bg.transform, new Vector2(0, 0.5f), new Vector2(0, 0), new Vector2(300, 30), Orange);
            fill.rectTransform.pivot = new Vector2(0, 0.5f);
            fill.rectTransform.anchoredPosition = Vector2.zero;
            return fill;
        }

        public void ShowGarage(int car)
        {
            var def = Catalog.PlayerCars[car];
            garageName.text = def.Name;
            garageCoins.text = "ALTIN  " + Save.Coins;
            SetBar(barSpeed, Mathf.InverseLerp(140, 320, def.MaxKmh));
            SetBar(barAccel, Mathf.InverseLerp(20, 55, def.Accel));
            SetBar(barHandling, Mathf.InverseLerp(6, 10, def.Handling));

            bool unlocked = Save.IsUnlocked(car);
            bool selected = Save.SelectedCar == car;
            if (!unlocked)
            {
                UiKit.SetText(garageAction, "SATIN AL");
                garageAction.GetComponent<Image>().color = Save.Coins >= def.Price ? Green : new Color(0.4f, 0.4f, 0.45f);
                garagePrice.text = def.Price + " altın";
            }
            else
            {
                UiKit.SetText(garageAction, selected ? "SEÇİLİ" : "SEÇ");
                garageAction.GetComponent<Image>().color = selected ? new Color(0.35f, 0.38f, 0.45f) : Green;
                garagePrice.text = "";
            }

            int paint = Save.Paint(car);
            for (int i = 0; i < swatches.Count; i++)
            {
                var outline = swatches[i].GetComponent<Outline>();
                outline.effectColor = i == paint ? Orange : new Color(0, 0, 0, 0.35f);
                outline.effectDistance = i == paint ? new Vector2(6, -6) : new Vector2(0, -6);
            }
            Show(garage);
        }

        static void SetBar(Image fill, float v) => fill.rectTransform.sizeDelta = new Vector2(300 * Mathf.Clamp01(v), 30);

        // ------------------------------------------------------------------ Gösterge + kontroller

        void BuildHud()
        {
            var t = hud.transform;
            hudScore = UiKit.Label(t, "0", 84, new Vector2(0.5f, 1), new Vector2(0, -80), new Vector2(800, 110));
            hudDistance = UiKit.Label(t, "", 40, new Vector2(0.5f, 1), new Vector2(0, -160), new Vector2(800, 60), color: new Color(1, 1, 1, 0.85f));
            UiKit.Button(t, "II", new Vector2(1, 1), new Vector2(-100, -90), new Vector2(120, 120), Glass, game.Pause, 54);

            var speedBox = UiKit.Panel(t, new Vector2(0.5f, 0), new Vector2(0, 110), new Vector2(360, 170), Glass).transform;
            hudSpeed = UiKit.Label(speedBox, "0", 96, new Vector2(0.5f, 0.5f), new Vector2(0, 18), new Vector2(340, 120));
            UiKit.Label(speedBox, "km/s", 34, new Vector2(0.5f, 0), new Vector2(0, 32), new Vector2(200, 50), color: new Color(1, 1, 1, 0.75f));

            steerButtons = UiKit.Rect("Steer", t, new Vector2(0, 0), new Vector2(0, 0), Vector2.zero, Vector2.zero);
            left = UiKit.Hold(steerButtons, "<", new Vector2(0, 0), new Vector2(170, 170), new Vector2(240, 240), Glass, 90);
            right = UiKit.Hold(steerButtons, ">", new Vector2(0, 0), new Vector2(440, 170), new Vector2(240, 240), Glass, 90);

            brake = UiKit.Hold(t, "FREN", new Vector2(1, 0), new Vector2(-470, 140), new Vector2(210, 200), new Color(Red.r, Red.g, Red.b, 0.55f), 44);
            gas = UiKit.Hold(t, "GAZ", new Vector2(1, 0), new Vector2(-190, 190), new Vector2(260, 300), new Color(Green.r, Green.g, Green.b, 0.6f), 56);
        }

        public void ShowHud()
        {
            steerButtons.gameObject.SetActive(!Save.TiltControl);
            Show(hud);
        }

        public bool Gas => hud.gameObject.activeInHierarchy && (gas.Held || Input.GetKey(KeyCode.UpArrow) || Input.GetKey(KeyCode.W));
        public bool Brake => hud.gameObject.activeInHierarchy && (brake.Held || Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.S));

        public float SteerInput()
        {
            float s = 0;
            if (left.Held || Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A)) s -= 1;
            if (right.Held || Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D)) s += 1;
            return s;
        }

        public void UpdateHud(GameManager g)
        {
            hudScore.text = g.Score.ToString();
            hudSpeed.text = Mathf.RoundToInt(g.SpeedKmh).ToString();
            hudSpeed.color = g.SpeedKmh >= 100f ? Gold : Color.white;
            hudDistance.text = g.DistanceKm.ToString("0.00") + " km" + (g.SpeedKmh >= 100f ? "   x" + (1f + (g.SpeedKmh - 100f) / 100f).ToString("0.0") : "");
        }

        public void Popup(string text)
        {
            popup.text = text;
            popupTimer = 1.1f;
        }

        public void Toast(string text)
        {
            toast.text = text;
            toastTimer = 1.8f;
        }

        public void ShowCrash()
        {
            steerButtons.gameObject.SetActive(false);
        }

        // ------------------------------------------------------------------ Duraklatma / oyun sonu

        void BuildPause()
        {
            var t = pause.transform;
            UiKit.Fill(t, new Color(0, 0, 0, 0.55f));
            UiKit.Label(t, "DURAKLATILDI", 96, new Vector2(0.5f, 0.68f), Vector2.zero, new Vector2(1200, 130));
            UiKit.Button(t, "DEVAM", new Vector2(0.5f, 0.45f), Vector2.zero, new Vector2(460, 130), Green, game.Resume, 60);
            UiKit.Button(t, "MENÜ", new Vector2(0.5f, 0.28f), Vector2.zero, new Vector2(460, 120), Blue, game.ShowMenu, 52);
        }

        public void ShowPause() => Show(pause);

        void BuildGameOver()
        {
            var t = over.transform;
            UiKit.Fill(t, new Color(0, 0, 0, 0.5f));
            var panel = UiKit.Panel(t, new Vector2(0.5f, 0.5f), Vector2.zero, new Vector2(900, 820), Dark).transform;
            overTitle = UiKit.Label(panel, "KAZA!", 110, new Vector2(0.5f, 1), new Vector2(0, -100), new Vector2(800, 140), color: Red);
            overScore = UiKit.Label(panel, "", 72, new Vector2(0.5f, 1), new Vector2(0, -230), new Vector2(800, 100));
            overBest = UiKit.Label(panel, "", 44, new Vector2(0.5f, 1), new Vector2(0, -310), new Vector2(800, 60), color: new Color(1, 1, 1, 0.8f));
            overStats = UiKit.Label(panel, "", 38, new Vector2(0.5f, 1), new Vector2(0, -375), new Vector2(800, 60), color: new Color(1, 1, 1, 0.75f));
            overCoins = UiKit.Label(panel, "", 52, new Vector2(0.5f, 1), new Vector2(0, -450), new Vector2(800, 70), color: Gold);
            UiKit.Button(panel, "TEKRAR", new Vector2(0.5f, 0), new Vector2(-190, 130), new Vector2(340, 130), Orange, game.StartRun, 56);
            UiKit.Button(panel, "MENÜ", new Vector2(0.5f, 0), new Vector2(190, 130), new Vector2(340, 130), Blue, game.ShowMenu, 52);
        }

        public void ShowGameOver(int score, int best, int coins, bool record, float km, int nearMisses)
        {
            overTitle.text = record ? "YENİ REKOR!" : "KAZA!";
            overTitle.color = record ? Gold : Red;
            overScore.text = "SKOR  " + score;
            overBest.text = "REKOR  " + best;
            overStats.text = km.ToString("0.00") + " km   •   " + nearMisses + " yakın geçiş";
            overCoins.text = "+" + coins + " ALTIN";
            Show(over);
        }
    }

    /// <summary>Zaman ölçeğinden bağımsız UI animasyon saati.</summary>
    public sealed class UiTicker : MonoBehaviour
    {
        public System.Action<float> OnTick;
        void Update() => OnTick?.Invoke(Time.unscaledDeltaTime);
    }
}
