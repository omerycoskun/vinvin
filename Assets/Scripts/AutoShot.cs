using System.Collections;
using System.IO;
using UnityEngine;

namespace VinVin
{
    /// <summary>
    /// Yalnızca "-autoshot &lt;klasör&gt;" komut satırı argümanıyla çalışır: menü, sürüş ve garaj
    /// ekranlarını otomatik gezip PNG kaydeder, sonra kapanır (görsel kontrol / mağaza görüntüleri).
    /// Normal oyunda hiçbir etkisi yoktur.
    /// </summary>
    public sealed class AutoShot : MonoBehaviour
    {
        public static bool Active { get; private set; }
        public static float Steer { get; private set; }
        public static bool Gas { get; private set; }

        string folder;
        int index;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        static void Init()
        {
            var args = System.Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length - 1; i++)
            {
                if (args[i] != "-autoshot") continue;
                Active = true;
                var go = new GameObject("AutoShot");
                DontDestroyOnLoad(go);
                go.AddComponent<AutoShot>().folder = args[i + 1];
            }
        }

        IEnumerator Start()
        {
            Directory.CreateDirectory(folder);
            PlayerPrefs.SetInt("coins", 4200);
            var game = FindAnyObjectByType<GameManager>();
            yield return new WaitForSeconds(2.5f);
            yield return Shot("1_menu");

            game.ShowGarage();
            yield return new WaitForSeconds(2.0f);
            yield return Shot("2_garage");
            game.GarageBrowse(1);
            game.GarageBrowse(1);
            game.GarageBrowse(1);
            yield return new WaitForSeconds(1.5f);
            yield return Shot("3_garage_sport");
            game.CloseGarage();

            game.StartRun();
            Gas = true;
            float t = 0;
            while (t < 9f && game.State == GameState.Playing)
            {
                Steer = Mathf.Sin(t * 0.9f) * 0.6f;
                t += Time.deltaTime;
                if (Mathf.Abs(t - 3f) < Time.deltaTime) yield return Shot("4_drive");
                if (Mathf.Abs(t - 7.5f) < Time.deltaTime) yield return Shot("5_drive_fast");
                yield return null;
            }
            Steer = 0;
            yield return new WaitForSeconds(0.5f);
            yield return Shot("6_after");
            Application.Quit();
        }

        IEnumerator Shot(string name)
        {
            yield return new WaitForEndOfFrame();
            var path = Path.Combine(folder, name + ".png");
            ScreenCapture.CaptureScreenshot(path);
            index++;
            yield return null;
        }
    }
}
