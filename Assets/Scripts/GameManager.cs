using System.Collections.Generic;
using UnityEngine;

namespace VinVin
{
    /// <summary>Uygulama açılınca tek bir GameManager oluşturur (sahne ayarı gerektirmez).</summary>
    public static class Bootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Boot()
        {
            if (Object.FindAnyObjectByType<GameManager>() != null) return;
            new GameObject("VinVin").AddComponent<GameManager>();
        }
    }

    public enum GameState { Menu, Garage, Playing, Paused, Crashing, GameOver }

    /// <summary>Oyun durumu, oyuncu aracı, trafik, kamera ve puanlama.</summary>
    public sealed class GameManager : MonoBehaviour
    {
        const float KmhToMs = 1f / 3.6f;
        const float RebaseDistance = 2000f;
        const float MinCruiseKmh = 40f;

        public GameState State { get; private set; } = GameState.Menu;

        // Sahne
        Camera cam;
        Light sun;
        WorldBuilder world;
        SoundFx sound;
        RaceUI ui;
        Material baseMaterial;

        // Oyuncu
        GameObject playerCar;
        List<Transform> playerWheels = new List<Transform>();
        PlayerCarDef carDef;
        float playerX, playerZ, lateralVel, speedKmh;
        float crashTimer;
        Vector3 crashSpin;

        // Trafik
        sealed class Vehicle
        {
            public GameObject Go;
            public TrafficDef Def;
            public int Lane;
            public float X, Z, SpeedKmh, TargetKmh;
            public bool Passed;
            public List<Transform> Wheels;
        }
        readonly List<Vehicle> traffic = new List<Vehicle>();
        readonly Dictionary<string, Stack<Vehicle>> pools = new Dictionary<string, Stack<Vehicle>>();
        readonly System.Random rng = new System.Random();
        Transform trafficRoot;

        // Puan
        float score, distance, nearMissCooldown;
        int nearMisses;
        public int Score => Mathf.FloorToInt(score);
        public float DistanceKm => distance / 1000f;
        public float SpeedKmh => speedKmh;

        // Garaj önizleme
        int previewCar;
        float orbit;

        // Kamera
        Vector3 camVel;
        float shake;

        void Awake()
        {
            Application.targetFrameRate = 60;
            Screen.sleepTimeout = SleepTimeout.NeverSleep;
            QualitySettings.shadowDistance = 90f;

            SetupCameraAndLight();
            var probe = GameObject.CreatePrimitive(PrimitiveType.Cube);
            baseMaterial = probe.GetComponent<MeshRenderer>().sharedMaterial;
            Destroy(probe);

            world = new WorldBuilder(transform, baseMaterial);
            trafficRoot = new GameObject("Traffic").transform;
            trafficRoot.SetParent(transform, false);
            sound = gameObject.AddComponent<SoundFx>();
            ui = new RaceUI(this, transform);

            SpawnPlayer(Save.SelectedCar);
            playerZ = 0;
            world.UpdateAround(playerZ);
            PopulateIdleTraffic();
            ShowMenu();
        }

        void SetupCameraAndLight()
        {
            cam = Camera.main;
            if (cam == null)
            {
                cam = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener)).GetComponent<Camera>();
                cam.tag = "MainCamera";
            }
            cam.fieldOfView = 60f;
            cam.nearClipPlane = 0.3f;
            cam.farClipPlane = 900f;

            sun = Object.FindAnyObjectByType<Light>();
            if (sun == null || sun.type != LightType.Directional)
                sun = new GameObject("Sun").AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.color = new Color(1f, 0.93f, 0.82f);
            sun.intensity = 1.25f;
            sun.shadows = LightShadows.Soft;
            sun.shadowStrength = 0.75f;
            sun.transform.rotation = Quaternion.Euler(42f, -35f, 0f);

            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.Linear;
            RenderSettings.fogColor = new Color(0.72f, 0.82f, 0.92f);
            RenderSettings.fogStartDistance = 120f;
            RenderSettings.fogEndDistance = 520f;
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.62f, 0.72f, 0.86f);
            RenderSettings.ambientEquatorColor = new Color(0.55f, 0.58f, 0.55f);
            RenderSettings.ambientGroundColor = new Color(0.30f, 0.32f, 0.28f);
            if (RenderSettings.skybox == null) cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = RenderSettings.fogColor;
        }

        // ------------------------------------------------------------------ Oyuncu

        void SpawnPlayer(int index)
        {
            if (playerCar != null) Destroy(playerCar);
            carDef = Catalog.PlayerCars[index];
            playerCar = CarFactory.Create(carDef.Model, carDef.Length, Catalog.Paints[Save.Paint(index)], transform);
            playerCar.name = "Player";
            playerWheels = CarFactory.Wheels(playerCar);
            playerX = WorldBuilder.LaneX(1);
            PlacePlayer();
        }

        void PlacePlayer()
        {
            playerCar.transform.position = new Vector3(playerX, 0, playerZ);
            float yaw = Mathf.Clamp(lateralVel * 2.2f, -14f, 14f);
            float roll = Mathf.Clamp(-lateralVel * 0.6f, -4f, 4f);
            playerCar.transform.rotation = Quaternion.Euler(0, yaw, roll);
        }

        // ------------------------------------------------------------------ Durumlar

        public void ShowMenu()
        {
            State = GameState.Menu;
            Time.timeScale = 1f;
            ResetRun(false);
            ui.ShowMenu();
        }

        public void ShowGarage()
        {
            State = GameState.Garage;
            previewCar = Save.SelectedCar;
            ui.ShowGarage(previewCar);
        }

        public void GarageBrowse(int dir)
        {
            previewCar = (previewCar + dir + Catalog.PlayerCars.Length) % Catalog.PlayerCars.Length;
            SpawnPlayer(previewCar);
            sound.Click();
            ui.ShowGarage(previewCar);
        }

        public void GarageSelectOrBuy()
        {
            var def = Catalog.PlayerCars[previewCar];
            if (!Save.IsUnlocked(previewCar))
            {
                if (Save.Coins < def.Price) { ui.Toast("Yeterli altın yok"); return; }
                Save.Coins -= def.Price;
                Save.Unlock(previewCar);
                ui.Toast(def.Name + " alındı!");
            }
            Save.SelectedCar = previewCar;
            sound.Click();
            ui.ShowGarage(previewCar);
        }

        public void GaragePaint(int paint)
        {
            if (!Save.IsUnlocked(previewCar)) { ui.Toast("Önce aracı satın al"); return; }
            if (Save.Paint(previewCar) == paint) return;
            if (paint != 0)
            {
                if (Save.Coins < Catalog.PaintPrice) { ui.Toast("Yeterli altın yok"); return; }
                Save.Coins -= Catalog.PaintPrice;
            }
            Save.SetPaint(previewCar, paint);
            CarFactory.Tint(playerCar, Catalog.Paints[paint]);
            sound.Click();
            ui.ShowGarage(previewCar);
        }

        public void CloseGarage()
        {
            if (previewCar != Save.SelectedCar) SpawnPlayer(Save.SelectedCar);
            ShowMenu();
        }

        public void StartRun()
        {
            if (!Save.IsUnlocked(Save.SelectedCar)) Save.SelectedCar = 0;
            SpawnPlayer(Save.SelectedCar);
            ResetRun(true);
            State = GameState.Playing;
            speedKmh = 70f;
            ui.ShowHud();
            sound.Click();
        }

        public void Pause()
        {
            if (State != GameState.Playing) return;
            State = GameState.Paused;
            Time.timeScale = 0f;
            ui.ShowPause();
        }

        public void Resume()
        {
            if (State != GameState.Paused) return;
            State = GameState.Playing;
            Time.timeScale = 1f;
            ui.ShowHud();
        }

        void ResetRun(bool clearTraffic)
        {
            score = 0; distance = 0; nearMisses = 0; nearMissCooldown = 0;
            lateralVel = 0; crashTimer = 0; shake = 0;
            playerX = WorldBuilder.LaneX(1);
            if (clearTraffic)
            {
                foreach (var v in traffic) Recycle(v);
                traffic.Clear();
            }
        }

        void OnApplicationPause(bool paused)
        {
            if (paused) Pause();
        }

        // ------------------------------------------------------------------ Döngü

        void Update()
        {
            float dt = Time.deltaTime;
            switch (State)
            {
                case GameState.Playing:
                    UpdateDriving(dt);
                    UpdateTraffic(dt);
                    CheckCollisions();
                    ui.UpdateHud(this);
                    break;
                case GameState.Crashing:
                    UpdateCrash(dt);
                    UpdateTraffic(dt);
                    break;
                case GameState.Menu:
                case GameState.Garage:
                case GameState.GameOver:
                    speedKmh = 0;
                    UpdateTraffic(dt);
                    break;
            }

            if (State != GameState.Paused)
            {
                world.UpdateAround(playerZ);
                if (State != GameState.Crashing) PlacePlayer();
                SpinWheels(playerWheels, speedKmh, dt);
                UpdateCamera(dt);
                MaybeRebase();
            }

            bool engineOn = State == GameState.Playing;
            sound.Engine(engineOn, carDef != null ? speedKmh / carDef.MaxKmh : 0f);
        }

        void UpdateDriving(float dt)
        {
            float steer = ui.SteerInput();
            if (Save.TiltControl)
            {
                var a = Input.acceleration;
                // Yatay (landscape) tutuşta sağa/sola eğim y ekseninde okunur.
                float tilt = Screen.orientation == ScreenOrientation.LandscapeRight ? a.y : -a.y;
                steer = Mathf.Clamp(tilt * 2.4f, -1f, 1f);
            }

            float targetLat = steer * carDef.Handling * Mathf.Lerp(0.8f, 1.15f, speedKmh / carDef.MaxKmh);
            lateralVel = Mathf.MoveTowards(lateralVel, targetLat, dt * 30f);
            playerX += lateralVel * dt;
            float limit = WorldBuilder.RoadHalfWidth - 1.0f;
            if (Mathf.Abs(playerX) > limit)
            {
                playerX = Mathf.Sign(playerX) * limit;
                lateralVel = 0;
                speedKmh = Mathf.Max(MinCruiseKmh, speedKmh - dt * 40f); // bariyere sürtünme
            }

            if (ui.Gas) speedKmh = Mathf.MoveTowards(speedKmh, carDef.MaxKmh, carDef.Accel * dt * Mathf.Lerp(1.2f, 0.45f, speedKmh / carDef.MaxKmh));
            else if (ui.Brake) speedKmh = Mathf.MoveTowards(speedKmh, MinCruiseKmh * 0.5f, 90f * dt);
            else speedKmh = Mathf.MoveTowards(speedKmh, MinCruiseKmh, 10f * dt);

            float move = speedKmh * KmhToMs * dt;
            playerZ += move;
            distance += move;
            float mult = speedKmh >= 100f ? 1f + (speedKmh - 100f) / 100f : 0.5f;
            score += move * mult;
            nearMissCooldown -= dt;
        }

        void UpdateCrash(float dt)
        {
            crashTimer += dt;
            speedKmh = Mathf.MoveTowards(speedKmh, 0, 160f * dt);
            playerZ += speedKmh * KmhToMs * dt;
            var t = playerCar.transform;
            t.position = new Vector3(playerX, Mathf.Max(0, Mathf.Sin(Mathf.Min(crashTimer, 0.6f) / 0.6f * Mathf.PI) * 1.2f), playerZ);
            t.Rotate(crashSpin * dt, Space.World);
            if (crashTimer > 1.4f)
            {
                State = GameState.GameOver;
                int earned = Mathf.Max(1, Score / 20);
                bool record = Score > Save.Best;
                if (record) Save.Best = Score;
                Save.Coins += earned;
                ui.ShowGameOver(Score, Save.Best, earned, record, DistanceKm, nearMisses);
            }
        }

        // ------------------------------------------------------------------ Trafik

        void PopulateIdleTraffic()
        {
            for (int i = 0; i < 10; i++) SpawnVehicle(playerZ + 25f + i * 30f, idle: true);
        }

        void UpdateTraffic(float dt)
        {
            // Aynı şeritte öndekine yaklaşan yavaşlasın.
            for (int i = 0; i < traffic.Count; i++)
            {
                var v = traffic[i];
                float desired = v.TargetKmh;
                for (int j = 0; j < traffic.Count; j++)
                {
                    if (i == j) continue;
                    var o = traffic[j];
                    if (o.Lane != v.Lane) continue;
                    float gap = o.Z - v.Z - (o.Def.Length + v.Def.Length) * 0.5f;
                    if (gap > 0 && gap < 14f) desired = Mathf.Min(desired, o.SpeedKmh - (14f - gap));
                }
                v.SpeedKmh = Mathf.MoveTowards(v.SpeedKmh, Mathf.Max(0, desired), 25f * dt);
                v.Z += v.SpeedKmh * KmhToMs * dt;
                v.Go.transform.position = new Vector3(v.X, 0, v.Z);
                SpinWheels(v.Wheels, v.SpeedKmh, dt);
            }

            // Arkada kalanları geri dönüştür.
            for (int i = traffic.Count - 1; i >= 0; i--)
            {
                if (traffic[i].Z < playerZ - 40f || traffic[i].Z > playerZ + 700f)
                {
                    Recycle(traffic[i]);
                    traffic.RemoveAt(i);
                }
            }

            if (State != GameState.Playing) return;

            // Yoğunluk: hızla ve mesafeyle artar.
            int wanted = Mathf.Clamp(8 + Mathf.FloorToInt(distance / 600f), 8, 18);
            int guard = 0;
            while (traffic.Count < wanted && guard++ < 4)
            {
                float z = playerZ + 230f + (float)rng.NextDouble() * 160f;
                SpawnVehicle(z, idle: false);
            }
        }

        void SpawnVehicle(float z, bool idle)
        {
            int lane = rng.Next(WorldBuilder.Lanes);
            var def = Catalog.PickTraffic(rng);
            // Aynı şeritte çok yakın araç varsa vazgeç.
            foreach (var o in traffic)
                if (o.Lane == lane && Mathf.Abs(o.Z - z) < (o.Def.Length + def.Length) * 0.5f + 12f) return;
            // Oyuncunun önünü tamamen kapatan duvarları önle: aynı z bandında en fazla 3 araç.
            int band = 0;
            foreach (var o in traffic) if (Mathf.Abs(o.Z - z) < 10f) band++;
            if (band >= WorldBuilder.Lanes - 1) return;

            Vehicle v = null;
            if (pools.TryGetValue(def.Model, out var stack) && stack.Count > 0) v = stack.Pop();
            if (v == null)
            {
                var tint = def.Tintable ? Catalog.Paints[rng.Next(Catalog.Paints.Length)] : Color.white;
                var go = CarFactory.Create(def.Model, def.Length, tint, trafficRoot);
                v = new Vehicle { Go = go, Def = def, Wheels = CarFactory.Wheels(go) };
            }
            v.Go.SetActive(true);
            v.Lane = lane;
            v.X = WorldBuilder.LaneX(lane) + ((float)rng.NextDouble() - 0.5f) * 0.4f;
            v.Z = z;
            bool heavy = def.Length > 5.5f;
            v.TargetKmh = idle ? 0 : (heavy ? 45f : 55f) + (float)rng.NextDouble() * (heavy ? 25f : 40f);
            v.SpeedKmh = v.TargetKmh;
            v.Passed = false;
            v.Go.transform.position = new Vector3(v.X, 0, v.Z);
            v.Go.transform.rotation = Quaternion.identity;
            traffic.Add(v);
        }

        void Recycle(Vehicle v)
        {
            v.Go.SetActive(false);
            if (!pools.TryGetValue(v.Def.Model, out var stack)) pools[v.Def.Model] = stack = new Stack<Vehicle>();
            if (stack.Count < 6) stack.Push(v); else Destroy(v.Go);
        }

        static void SpinWheels(List<Transform> wheels, float kmh, float dt)
        {
            if (wheels == null) return;
            float deg = kmh * KmhToMs / 0.35f * Mathf.Rad2Deg * dt;
            foreach (var w in wheels) w.Rotate(deg, 0, 0, Space.Self);
        }

        // ------------------------------------------------------------------ Çarpışma / yakın geçiş

        void CheckCollisions()
        {
            const float playerHalfW = 0.95f;
            float playerHalfL = carDef.Length * 0.5f;
            foreach (var v in traffic)
            {
                float halfW = v.Def.Length > 5.5f ? 1.25f : 1.0f;
                float dx = Mathf.Abs(v.X - playerX);
                float dz = Mathf.Abs(v.Z - playerZ);
                if (dx < playerHalfW + halfW - 0.1f && dz < playerHalfL + v.Def.Length * 0.5f - 0.2f)
                {
                    Crash(v);
                    return;
                }

                // Yakın geçiş: aracı geçerken yanal boşluk dar ve hız yüksekse bonus.
                if (!v.Passed && v.Z < playerZ - v.Def.Length * 0.5f)
                {
                    v.Passed = true;
                    float gap = dx - playerHalfW - halfW;
                    if (gap < 0.9f && speedKmh >= 90f && nearMissCooldown <= 0)
                    {
                        nearMisses++;
                        int bonus = 50 + Mathf.RoundToInt((speedKmh - 90f) * 0.8f);
                        score += bonus;
                        nearMissCooldown = 0.25f;
                        sound.Whoosh();
                        ui.Popup("YAKIN GEÇİŞ +" + bonus);
                    }
                }
            }
        }

        void Crash(Vehicle hit)
        {
            State = GameState.Crashing;
            crashTimer = 0;
            shake = 0.6f;
            float side = Mathf.Sign(playerX - hit.X);
            crashSpin = new Vector3(0, side * 420f, side * 160f);
            hit.TargetKmh = 0;
            sound.Crash();
            ui.ShowCrash();
        }

        // ------------------------------------------------------------------ Kamera

        void UpdateCamera(float dt)
        {
            Vector3 target;
            Vector3 look;
            if (State == GameState.Menu || State == GameState.Garage || State == GameState.GameOver)
            {
                orbit += dt * (State == GameState.Garage ? 18f : 8f);
                float r = State == GameState.Garage ? 7.5f : 10f;
                var p = playerCar.transform.position;
                target = p + new Vector3(Mathf.Sin(orbit * Mathf.Deg2Rad) * r, State == GameState.Garage ? 2.2f : 3.2f, -Mathf.Cos(orbit * Mathf.Deg2Rad) * r);
                look = p + Vector3.up * 0.9f;
                cam.transform.position = Vector3.SmoothDamp(cam.transform.position, target, ref camVel, 0.35f);
                cam.fieldOfView = Mathf.Lerp(cam.fieldOfView, 50f, dt * 3f);
            }
            else
            {
                float k = carDef != null ? Mathf.Clamp01(speedKmh / carDef.MaxKmh) : 0;
                var p = new Vector3(playerX * 0.85f, 0, playerZ);
                target = p + new Vector3(0, 3.1f + k * 0.4f, -7.8f - k * 1.6f);
                look = new Vector3(playerX * 0.6f, 1.0f, playerZ + 14f);
                cam.transform.position = Vector3.SmoothDamp(cam.transform.position, target, ref camVel, 0.08f);
                cam.fieldOfView = Mathf.Lerp(cam.fieldOfView, 60f + k * 16f, dt * 2.5f);
            }

            var rot = Quaternion.LookRotation(look - cam.transform.position);
            if (shake > 0)
            {
                shake -= dt;
                rot *= Quaternion.Euler(Random.Range(-1f, 1f) * shake * 6f, Random.Range(-1f, 1f) * shake * 6f, 0);
            }
            cam.transform.rotation = rot;
        }

        void MaybeRebase()
        {
            if (playerZ < RebaseDistance) return;
            float dz = -RebaseDistance;
            playerZ += dz;
            foreach (var v in traffic) { v.Z += dz; v.Go.transform.position += new Vector3(0, 0, dz); }
            world.Rebase(dz);
            cam.transform.position += new Vector3(0, 0, dz);
            if (playerCar != null) playerCar.transform.position += new Vector3(0, 0, dz);
        }
    }
}
