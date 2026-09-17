using System.Collections.Generic;
using UnityEngine;

namespace VinVin
{
    /// <summary>
    /// Araç modellerini Resources'tan yükler; uzunluğu +Z ekseninde olacak şekilde
    /// döndürür, istenen boya ölçeklenir, pivotu tabanın ortasına alır.
    /// </summary>
    public static class CarFactory
    {
        static readonly Dictionary<string, GameObject> Cache = new Dictionary<string, GameObject>();
        static readonly int ColorId = Shader.PropertyToID("_Color");
        static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        /// <summary>Modelin ön yönü için ek dönüş (model paketine göre ayarlanır).</summary>
        public static float ModelYawOffset = 180f;

        public static GameObject Prefab(string model)
        {
            if (Cache.TryGetValue(model, out var go)) return go;
            go = Resources.Load<GameObject>("Cars/" + model);
            if (go == null) Debug.LogError("Model bulunamadı: Cars/" + model);
            Cache[model] = go;
            return go;
        }

        /// <summary>Yeni araç örneği: kök (pivot = taban ortası, ön = +Z) + içindeki model.</summary>
        public static GameObject Create(string model, float length, Color tint, Transform parent = null)
        {
            var root = new GameObject(model);
            if (parent != null) root.transform.SetParent(parent, false);

            var prefab = Prefab(model);
            GameObject body = prefab != null ? Object.Instantiate(prefab) : GameObject.CreatePrimitive(PrimitiveType.Cube);
            body.name = "Model";
            foreach (var col in body.GetComponentsInChildren<Collider>()) Object.Destroy(col);

            var holder = new GameObject("Holder").transform;
            holder.SetParent(root.transform, false);
            body.transform.SetParent(holder, false);
            body.transform.localPosition = Vector3.zero;

            // Uzun eksen X ise Z'ye çevir.
            var b = LocalBounds(body, holder);
            float yaw = ModelYawOffset;
            if (b.size.x > b.size.z) yaw += 90f;
            body.transform.localRotation = Quaternion.Euler(0, yaw, 0) * body.transform.localRotation;

            // Ölçek: model uzunluğu = length.
            b = LocalBounds(body, holder);
            float s = b.size.z > 0.001f ? length / b.size.z : 1f;
            holder.localScale = Vector3.one * s;

            // Pivot: taban ortası.
            b = LocalBounds(body, holder);
            body.transform.localPosition -= new Vector3(b.center.x, b.min.y, b.center.z);

            Tint(root, tint);
            return root;
        }

        /// <summary>Holder koordinatlarında tüm renderer'ları kapsayan kutu.</summary>
        static Bounds LocalBounds(GameObject go, Transform space)
        {
            var renderers = go.GetComponentsInChildren<Renderer>();
            bool has = false;
            var bounds = new Bounds();
            foreach (var r in renderers)
            {
                var mf = r.GetComponent<MeshFilter>();
                if (mf == null || mf.sharedMesh == null) continue;
                var mb = mf.sharedMesh.bounds;
                var m = space.worldToLocalMatrix * r.transform.localToWorldMatrix;
                for (int i = 0; i < 8; i++)
                {
                    var corner = mb.center + Vector3.Scale(mb.extents, new Vector3((i & 1) == 0 ? -1 : 1, (i & 2) == 0 ? -1 : 1, (i & 4) == 0 ? -1 : 1));
                    var p = m.MultiplyPoint3x4(corner);
                    if (!has) { bounds = new Bounds(p, Vector3.zero); has = true; }
                    else bounds.Encapsulate(p);
                }
            }
            return bounds;
        }

        public static void Tint(GameObject root, Color tint)
        {
            var block = new MaterialPropertyBlock();
            foreach (var r in root.GetComponentsInChildren<Renderer>())
            {
                r.GetPropertyBlock(block);
                block.SetColor(ColorId, tint);
                block.SetColor(BaseColorId, tint);
                r.SetPropertyBlock(block);
                r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
            }
        }

        /// <summary>İsminde "wheel" geçen alt nesneler (tekerlek dönüşü için).</summary>
        public static List<Transform> Wheels(GameObject root)
        {
            var list = new List<Transform>();
            foreach (var t in root.GetComponentsInChildren<Transform>())
            {
                if (t.name.ToLowerInvariant().Contains("wheel")) list.Add(t);
            }
            return list;
        }
    }
}
