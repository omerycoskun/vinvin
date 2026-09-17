using System.IO;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;

namespace VinVin.EditorTools
{
    /// <summary>Xcode projesine App Store için gerekli Info.plist anahtarlarını ekler.</summary>
    public static class IosPostProcess
    {
        [PostProcessBuild(100)]
        public static void OnPostProcessBuild(BuildTarget target, string path)
        {
            if (target != BuildTarget.iOS) return;
            var plistPath = Path.Combine(path, "Info.plist");
            var plist = new PlistDocument();
            plist.ReadFromFile(plistPath);
            var root = plist.root;

            // Standart dışı şifreleme yok → her yüklemede ihracat uyumluluğu sorusu çıkmaz.
            root.SetBoolean("ITSAppUsesNonExemptEncryption", false);
            root.SetBoolean("UIRequiresFullScreen", true);
            root.SetString("CFBundleDisplayName", "Vın Vın");

            // Reklam/izleme yok: eski projeden kalan izleme açıklaması eklenmez.
            if (root.values.ContainsKey("NSUserTrackingUsageDescription"))
                root.values.Remove("NSUserTrackingUsageDescription");

            plist.WriteToFile(plistPath);
        }
    }
}
