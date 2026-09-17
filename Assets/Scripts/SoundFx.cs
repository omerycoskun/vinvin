using UnityEngine;

namespace VinVin
{
    /// <summary>Kodla üretilen sesler: motor döngüsü, çarpma, yakın geçiş, tıklama.</summary>
    public sealed class SoundFx : MonoBehaviour
    {
        const int Rate = 44100;
        AudioSource engine;
        AudioSource oneShot;
        AudioClip crash, whoosh, click;

        void Awake()
        {
            engine = gameObject.AddComponent<AudioSource>();
            engine.clip = MakeEngine();
            engine.loop = true;
            engine.volume = 0f;
            engine.playOnAwake = false;
            oneShot = gameObject.AddComponent<AudioSource>();
            oneShot.playOnAwake = false;
            crash = MakeCrash();
            whoosh = MakeWhoosh();
            click = MakeClick();
        }

        static AudioClip MakeEngine()
        {
            int n = Rate; // 1 sn tam döngü
            var data = new float[n];
            const float f = 55f; // taban frekans (tam sayı döngü → dikişsiz)
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / Rate;
                float saw = 2f * (t * f - Mathf.Floor(0.5f + t * f));
                float h2 = Mathf.Sin(2 * Mathf.PI * f * 2 * t) * 0.35f;
                float h3 = Mathf.Sin(2 * Mathf.PI * f * 3 * t) * 0.18f;
                float wobble = 1f + 0.08f * Mathf.Sin(2 * Mathf.PI * 11f * t);
                data[i] = (saw * 0.45f + h2 + h3) * 0.35f * wobble;
            }
            var clip = AudioClip.Create("engine", n, 1, Rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        static AudioClip MakeCrash()
        {
            int n = (int)(Rate * 0.9f);
            var data = new float[n];
            var rng = new System.Random(3);
            float lp = 0;
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / n;
                float noise = (float)rng.NextDouble() * 2f - 1f;
                lp += (noise - lp) * 0.25f;
                float thump = Mathf.Sin(2 * Mathf.PI * 70f * i / Rate) * Mathf.Exp(-t * 14f);
                data[i] = (lp * 0.9f + thump * 0.8f) * Mathf.Exp(-t * 5f);
            }
            var clip = AudioClip.Create("crash", n, 1, Rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        static AudioClip MakeWhoosh()
        {
            int n = (int)(Rate * 0.35f);
            var data = new float[n];
            var rng = new System.Random(5);
            float lp = 0;
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / n;
                float noise = (float)rng.NextDouble() * 2f - 1f;
                lp += (noise - lp) * (0.05f + 0.3f * t);
                data[i] = lp * Mathf.Sin(Mathf.PI * t) * 0.9f;
            }
            var clip = AudioClip.Create("whoosh", n, 1, Rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        static AudioClip MakeClick()
        {
            int n = (int)(Rate * 0.06f);
            var data = new float[n];
            for (int i = 0; i < n; i++)
            {
                float t = (float)i / n;
                data[i] = Mathf.Sin(2 * Mathf.PI * 880f * i / Rate) * (1f - t) * 0.4f;
            }
            var clip = AudioClip.Create("click", n, 1, Rate, false);
            clip.SetData(data, 0);
            return clip;
        }

        /// <summary>Motor sesi: 0..1 devir.</summary>
        public void Engine(bool on, float rev)
        {
            if (!Save.Sound) on = false;
            if (on && !engine.isPlaying) engine.Play();
            engine.volume = Mathf.MoveTowards(engine.volume, on ? 0.35f : 0f, Time.unscaledDeltaTime * 2f);
            engine.pitch = 0.55f + Mathf.Clamp01(rev) * 1.5f;
            if (!on && engine.volume <= 0.001f && engine.isPlaying) engine.Stop();
        }

        public void Crash() { if (Save.Sound) oneShot.PlayOneShot(crash, 1f); }
        public void Whoosh() { if (Save.Sound) oneShot.PlayOneShot(whoosh, 0.8f); }
        public void Click() { if (Save.Sound) oneShot.PlayOneShot(click, 0.7f); }
    }
}
