using System.Collections.Generic;
using UnityEngine;

namespace VinVin
{
    /// <summary>
    /// Sonsuz otoyol: tekrar kullanılan yol parçaları (asfalt, şerit çizgileri,
    /// bariyer, ağaç, lamba), oyuncuyu takip eden zemin ve uzak tepeler.
    /// Her parça malzemeye göre birleştirilmiş birkaç mesh'ten oluşur (az draw call).
    /// </summary>
    public sealed class WorldBuilder
    {
        public const int Lanes = 4;
        public const float LaneWidth = 3.6f;
        public const float SegmentLength = 50f;
        public static float RoadHalfWidth => Lanes * LaneWidth * 0.5f;

        public static float LaneX(int lane) => (lane - (Lanes - 1) * 0.5f) * LaneWidth;

        readonly Transform root;
        readonly Material baseMat;
        readonly List<Transform> segments = new List<Transform>();
        readonly List<GameObject> prototypes = new List<GameObject>();
        Transform ground;
        Transform hills;
        float nextZ;
        int variant;

        readonly Dictionary<Color, Material> mats = new Dictionary<Color, Material>();

        public WorldBuilder(Transform parent, Material baseMaterial)
        {
            baseMat = baseMaterial;
            root = new GameObject("World").transform;
            root.SetParent(parent, false);
            for (int v = 0; v < 3; v++) prototypes.Add(BuildSegmentPrototype(v));
            BuildGround();
            BuildHills();
        }

        Material Mat(Color c, float gloss = 0.1f)
        {
            if (mats.TryGetValue(c, out var m)) return m;
            m = new Material(baseMat) { color = c, enableInstancing = true };
            if (m.HasProperty("_Glossiness")) m.SetFloat("_Glossiness", gloss);
            if (m.HasProperty("_Smoothness")) m.SetFloat("_Smoothness", gloss);
            mats[c] = m;
            return m;
        }

        static readonly Color Asphalt = new Color(0.20f, 0.21f, 0.23f);
        static readonly Color Paint = new Color(0.95f, 0.95f, 0.92f);
        static readonly Color YellowPaint = new Color(0.98f, 0.80f, 0.20f);
        static readonly Color Shoulder = new Color(0.36f, 0.35f, 0.33f);
        static readonly Color Grass = new Color(0.36f, 0.56f, 0.26f);
        static readonly Color Rail = new Color(0.72f, 0.74f, 0.78f);
        static readonly Color Trunk = new Color(0.40f, 0.27f, 0.17f);
        static readonly Color Leaves = new Color(0.22f, 0.48f, 0.22f);
        static readonly Color LeavesLight = new Color(0.40f, 0.62f, 0.25f);
        static readonly Color Pole = new Color(0.30f, 0.31f, 0.34f);
        static readonly Color Lamp = new Color(1.00f, 0.93f, 0.70f);

        /// <summary>Bir yol parçasının birleştirilmiş şablonu (gizli).</summary>
        GameObject BuildSegmentPrototype(int v)
        {
            var parts = new Dictionary<Color, List<CombineInstance>>();
            var rng = new System.Random(1234 + v * 97);

            void Add(PrimitiveType type, Color color, Vector3 pos, Vector3 scale, Quaternion rot)
            {
                var mesh = PrimitiveMesh(type);
                if (!parts.TryGetValue(color, out var list)) parts[color] = list = new List<CombineInstance>();
                list.Add(new CombineInstance { mesh = mesh, transform = Matrix4x4.TRS(pos, rot, scale) });
            }

            float L = SegmentLength;
            float hw = RoadHalfWidth;
            var q = Quaternion.identity;

            // Asfalt + banketler + çim şeritleri.
            Add(PrimitiveType.Cube, Asphalt, new Vector3(0, -0.05f, L / 2), new Vector3(hw * 2, 0.1f, L), q);
            Add(PrimitiveType.Cube, Shoulder, new Vector3(-hw - 1f, -0.04f, L / 2), new Vector3(2f, 0.1f, L), q);
            Add(PrimitiveType.Cube, Shoulder, new Vector3(hw + 1f, -0.04f, L / 2), new Vector3(2f, 0.1f, L), q);

            // Kenar çizgileri (sarı sol, beyaz sağ) + şerit kesik çizgileri.
            Add(PrimitiveType.Cube, YellowPaint, new Vector3(-hw + 0.25f, 0.005f, L / 2), new Vector3(0.18f, 0.02f, L), q);
            Add(PrimitiveType.Cube, Paint, new Vector3(hw - 0.25f, 0.005f, L / 2), new Vector3(0.18f, 0.02f, L), q);
            for (int lane = 1; lane < Lanes; lane++)
            {
                float x = -hw + lane * LaneWidth;
                for (float z = 1.5f; z < L; z += 10f)
                    Add(PrimitiveType.Cube, Paint, new Vector3(x, 0.005f, z + 1.5f), new Vector3(0.15f, 0.02f, 3f), q);
            }

            // Bariyer (iki yanda) + direkler.
            foreach (float side in new[] { -1f, 1f })
            {
                float rx = side * (hw + 2.2f);
                Add(PrimitiveType.Cube, Rail, new Vector3(rx, 0.75f, L / 2), new Vector3(0.12f, 0.32f, L), q);
                for (float z = 2f; z < L; z += 6f)
                    Add(PrimitiveType.Cube, Pole, new Vector3(rx + side * 0.12f, 0.4f, z), new Vector3(0.12f, 0.8f, 0.12f), q);
            }

            // Lambalar.
            foreach (float side in new[] { -1f, 1f })
            {
                float lx = side * (hw + 3.0f);
                float lz = v == 1 ? 10f : 35f;
                Add(PrimitiveType.Cylinder, Pole, new Vector3(lx, 3.5f, lz), new Vector3(0.18f, 3.5f, 0.18f), q);
                Add(PrimitiveType.Cube, Pole, new Vector3(lx - side * 1.1f, 6.9f, lz), new Vector3(2.4f, 0.14f, 0.2f), q);
                Add(PrimitiveType.Cube, Lamp, new Vector3(lx - side * 2.1f, 6.75f, lz), new Vector3(0.6f, 0.12f, 0.3f), q);
            }

            // Çim alanlar ve ağaçlar.
            Add(PrimitiveType.Cube, Grass, new Vector3(-hw - 22f, -0.08f, L / 2), new Vector3(40f, 0.1f, L), q);
            Add(PrimitiveType.Cube, Grass, new Vector3(hw + 22f, -0.08f, L / 2), new Vector3(40f, 0.1f, L), q);
            int trees = 4 + v;
            for (int i = 0; i < trees; i++)
            {
                float side = rng.NextDouble() < 0.5 ? -1f : 1f;
                float x = side * (hw + 6f + (float)rng.NextDouble() * 22f);
                float z = (float)rng.NextDouble() * L;
                float h = 3f + (float)rng.NextDouble() * 3f;
                Add(PrimitiveType.Cylinder, Trunk, new Vector3(x, h * 0.25f, z), new Vector3(0.35f, h * 0.25f, 0.35f), q);
                var leaf = rng.NextDouble() < 0.5 ? Leaves : LeavesLight;
                float r = 1.8f + (float)rng.NextDouble() * 1.4f;
                Add(PrimitiveType.Sphere, leaf, new Vector3(x, h * 0.5f + r * 0.7f, z), new Vector3(r * 1.6f, r * 1.9f, r * 1.6f),
                    Quaternion.Euler(0, (float)rng.NextDouble() * 360f, 0));
            }

            var proto = new GameObject("SegmentProto" + v);
            proto.transform.SetParent(root, false);
            foreach (var kv in parts)
            {
                var mesh = new Mesh { indexFormat = UnityEngine.Rendering.IndexFormat.UInt32 };
                mesh.CombineMeshes(kv.Value.ToArray(), true, true);
                mesh.RecalculateBounds();
                var part = new GameObject("Part");
                part.transform.SetParent(proto.transform, false);
                part.AddComponent<MeshFilter>().sharedMesh = mesh;
                var mr = part.AddComponent<MeshRenderer>();
                mr.sharedMaterial = Mat(kv.Key, kv.Key == Asphalt ? 0.25f : 0.08f);
                bool flat = kv.Key == Asphalt || kv.Key == Paint || kv.Key == YellowPaint || kv.Key == Shoulder || kv.Key == Grass;
                mr.shadowCastingMode = flat ? UnityEngine.Rendering.ShadowCastingMode.Off : UnityEngine.Rendering.ShadowCastingMode.On;
            }
            proto.SetActive(false);
            return proto;
        }

        static readonly Dictionary<PrimitiveType, Mesh> PrimitiveMeshes = new Dictionary<PrimitiveType, Mesh>();

        static Mesh PrimitiveMesh(PrimitiveType type)
        {
            if (PrimitiveMeshes.TryGetValue(type, out var m)) return m;
            var go = GameObject.CreatePrimitive(type);
            m = go.GetComponent<MeshFilter>().sharedMesh;
            Object.Destroy(go);
            PrimitiveMeshes[type] = m;
            return m;
        }

        void BuildGround()
        {
            var g = GameObject.CreatePrimitive(PrimitiveType.Plane);
            Object.Destroy(g.GetComponent<Collider>());
            g.name = "FarGround";
            g.transform.SetParent(root, false);
            g.transform.localScale = new Vector3(120f, 1f, 120f);
            g.transform.position = new Vector3(0, -0.15f, 0);
            var mr = g.GetComponent<MeshRenderer>();
            mr.sharedMaterial = Mat(new Color(0.33f, 0.52f, 0.24f));
            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            ground = g.transform;
        }

        void BuildHills()
        {
            hills = new GameObject("Hills").transform;
            hills.SetParent(root, false);
            var rng = new System.Random(77);
            var hillColors = new[] { new Color(0.42f, 0.55f, 0.40f), new Color(0.50f, 0.60f, 0.46f), new Color(0.58f, 0.64f, 0.55f) };
            for (int i = 0; i < 26; i++)
            {
                var h = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                Object.Destroy(h.GetComponent<Collider>());
                h.transform.SetParent(hills, false);
                float side = i % 2 == 0 ? -1f : 1f;
                float x = side * (140f + (float)rng.NextDouble() * 200f);
                float z = -200f + (float)rng.NextDouble() * 900f;
                float s = 80f + (float)rng.NextDouble() * 140f;
                h.transform.localPosition = new Vector3(x, -s * 0.25f, z);
                h.transform.localScale = new Vector3(s * 1.6f, s * 0.7f, s);
                var mr = h.GetComponent<MeshRenderer>();
                mr.sharedMaterial = Mat(hillColors[rng.Next(hillColors.Length)]);
                mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                mr.receiveShadows = false;
            }
        }

        /// <summary>Yol parçalarını oyuncunun önünde/arkasında tutar.</summary>
        public void UpdateAround(float playerZ)
        {
            float behind = playerZ - SegmentLength * 1.5f;
            float ahead = playerZ + 450f;

            if (segments.Count == 0) nextZ = Mathf.Floor(behind / SegmentLength) * SegmentLength;

            // Arkada kalanı öne taşı (yeniden kullan).
            while (segments.Count > 0 && segments[0].position.z + SegmentLength < behind)
            {
                var s = segments[0];
                segments.RemoveAt(0);
                s.position = new Vector3(0, 0, nextZ);
                nextZ += SegmentLength;
                segments.Add(s);
            }
            while (nextZ < ahead)
            {
                var seg = Object.Instantiate(prototypes[variant++ % prototypes.Count], root).transform;
                seg.gameObject.SetActive(true);
                seg.name = "Segment";
                seg.position = new Vector3(0, 0, nextZ);
                nextZ += SegmentLength;
                segments.Add(seg);
            }

            ground.position = new Vector3(0, -0.15f, playerZ + 200f);
            hills.position = new Vector3(0, 0, playerZ);
        }

        /// <summary>Kayan nokta hassasiyeti için tüm dünyayı z ekseninde kaydırır.</summary>
        public void Rebase(float dz)
        {
            foreach (var s in segments) s.position += new Vector3(0, 0, dz);
            nextZ += dz;
        }
    }
}
