using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace VinVin.EditorTools
{
    /// <summary>
    /// Projeyi koddan kurar (sahne, oyuncu ayarları, ikon) ve iOS Xcode projesini üretir.
    /// CI: -executeMethod VinVin.EditorTools.VinVinBuild.BuildiOS
    /// </summary>
    public static class VinVinBuild
    {
        const string ScenePath = "Assets/Scenes/Main.unity";
        const string BundleId = "com.omeryigitcoskun.vinvin";
        const string IconPath = "Assets/Icons/icon.png";

        [MenuItem("VinVin/Projeyi Kur")]
        public static void Setup()
        {
            // Sahne: kamera + ışık içeren boş sahne; oyun Bootstrap ile koddan kurulur.
            if (!File.Exists(ScenePath))
            {
                Directory.CreateDirectory("Assets/Scenes");
                var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
                EditorSceneManager.SaveScene(scene, ScenePath);
            }
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(ScenePath, true) };

            PlayerSettings.companyName = "Omer Yigit Coskun";
            PlayerSettings.productName = "Vın Vın";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.iOS, BundleId);
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, BundleId);
            PlayerSettings.bundleVersion = "1.0.0";
            var buildNumber = ArgValue("-buildNumber", Environment.GetEnvironmentVariable("BUILD_NUMBER"));
            PlayerSettings.iOS.buildNumber = string.IsNullOrEmpty(buildNumber) ? "1" : buildNumber;

            PlayerSettings.defaultInterfaceOrientation = UIOrientation.AutoRotation;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            PlayerSettings.allowedAutorotateToPortrait = false;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.iOS.requiresFullScreen = true;
            PlayerSettings.iOS.targetOSVersionString = "15.0";
            PlayerSettings.iOS.appleEnableAutomaticSigning = false;
            PlayerSettings.iOS.appInBackgroundBehavior = iOSAppInBackgroundBehavior.Suspend;
            PlayerSettings.statusBarHidden = true;
            PlayerSettings.SplashScreen.showUnityLogo = false;
            PlayerSettings.SplashScreen.show = false; // Personal lisansta yok sayılabilir
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.iOS, ScriptingImplementation.IL2CPP);
            PlayerSettings.SetManagedStrippingLevel(NamedBuildTarget.iOS, ManagedStrippingLevel.Low);
            PlayerSettings.colorSpace = ColorSpace.Gamma;

            // Eski Input Manager (Input.GetKey/acceleration) etkin olsun.
            SetActiveInputHandler(0);

            // Kalite: mobilde yumuşak gölge + orta çözünürlük.
            QualitySettings.shadows = ShadowQuality.All;
            QualitySettings.shadowResolution = ShadowResolution.Medium;
            QualitySettings.shadowDistance = 90f;

            ApplyIcon();
            ConfigureModelImports();
            AssetDatabase.SaveAssets();
            Debug.Log("[VinVin] Proje kuruldu.");
        }

        static void SetActiveInputHandler(int value)
        {
            var settings = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset").FirstOrDefault();
            if (settings == null) return;
            var so = new SerializedObject(settings);
            var prop = so.FindProperty("activeInputHandler");
            if (prop != null && prop.intValue != value)
            {
                prop.intValue = value;
                so.ApplyModifiedPropertiesWithoutUndo();
            }
        }

        static void ApplyIcon()
        {
            if (!File.Exists(IconPath)) return;
            AssetDatabase.ImportAsset(IconPath);
            var importer = (TextureImporter)AssetImporter.GetAtPath(IconPath);
            if (importer != null)
            {
                importer.textureType = TextureImporterType.Default;
                importer.alphaIsTransparency = false;
                importer.mipmapEnabled = false;
                importer.npotScale = TextureImporterNPOTScale.None;
                importer.textureCompression = TextureImporterCompression.Uncompressed;
                importer.SaveAndReimport();
            }
            var icon = AssetDatabase.LoadAssetAtPath<Texture2D>(IconPath);
            PlayerSettings.SetIcons(NamedBuildTarget.Unknown, new[] { icon }, IconKind.Any);
            var sizes = PlayerSettings.GetIconSizes(NamedBuildTarget.iOS, IconKind.Any);
            PlayerSettings.SetIcons(NamedBuildTarget.iOS, Enumerable.Repeat(icon, sizes.Length).ToArray(), IconKind.Any);
        }

        /// <summary>Araç modelleri: kolaysız ölçek, malzeme modelden, gereksiz animasyon/collider yok.</summary>
        static void ConfigureModelImports()
        {
            foreach (var guid in AssetDatabase.FindAssets("t:Model", new[] { "Assets/Resources/Cars" }))
            {
                var path = AssetDatabase.GUIDToAssetPath(guid);
                if (!(AssetImporter.GetAtPath(path) is ModelImporter mi)) continue;
                bool changed = false;
                if (mi.importAnimation) { mi.importAnimation = false; changed = true; }
                if (mi.addCollider) { mi.addCollider = false; changed = true; }
                if (mi.isReadable) { mi.isReadable = false; changed = true; }
                if (mi.materialImportMode != ModelImporterMaterialImportMode.ImportStandard)
                {
                    mi.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
                    changed = true;
                }
                if (changed) mi.SaveAndReimport();
            }
        }

        static string ArgValue(string name, string fallback)
        {
            var args = Environment.GetCommandLineArgs();
            for (int i = 0; i < args.Length - 1; i++)
                if (args[i] == name) return args[i + 1];
            return fallback;
        }

        public static void BuildiOS()
        {
            Setup();
            var output = ArgValue("-customBuildPath", "build/iOS/iOS");
            // game-ci, -customBuildPath'i dosya yolu gibi verir; Xcode projesi klasör ister.
            if (output.EndsWith(".app") || output.EndsWith(".ipa")) output = Path.GetDirectoryName(output);
            Directory.CreateDirectory(output);

            var options = new BuildPlayerOptions
            {
                scenes = new[] { ScenePath },
                locationPathName = output,
                target = BuildTarget.iOS,
                options = BuildOptions.None,
            };
            var report = BuildPipeline.BuildPlayer(options);
            Debug.Log($"[VinVin] iOS build: {report.summary.result}, {report.summary.totalErrors} hata, çıktı {output}");
            if (report.summary.result != BuildResult.Succeeded) EditorApplication.Exit(1);
        }
    }
}
