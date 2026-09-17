using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace VinVin
{
    /// <summary>Kodla uGUI oluşturma yardımcıları (sahne/prefab gerektirmez).</summary>
    public static class UiKit
    {
        static Font font;
        static Sprite rounded;

        public static Font Font => font != null ? font : (font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));

        /// <summary>Yuvarlatılmış köşeli, 9-dilimli beyaz sprite.</summary>
        public static Sprite Rounded
        {
            get
            {
                if (rounded != null) return rounded;
                const int s = 64;
                const int r = 20;
                var tex = new Texture2D(s, s, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp };
                var px = new Color32[s * s];
                for (int y = 0; y < s; y++)
                for (int x = 0; x < s; x++)
                {
                    float dx = Mathf.Max(0, Mathf.Max(r - x, x - (s - 1 - r)));
                    float dy = Mathf.Max(0, Mathf.Max(r - y, y - (s - 1 - r)));
                    float d = Mathf.Sqrt(dx * dx + dy * dy);
                    byte a = (byte)(Mathf.Clamp01(r - d + 0.5f) * 255);
                    px[y * s + x] = new Color32(255, 255, 255, a);
                }
                tex.SetPixels32(px);
                tex.Apply();
                rounded = Sprite.Create(tex, new Rect(0, 0, s, s), new Vector2(0.5f, 0.5f), 100, 0, SpriteMeshType.FullRect, new Vector4(r, r, r, r));
                return rounded;
            }
        }

        public static Canvas CreateCanvas(Transform parent)
        {
            var go = new GameObject("UI", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            go.transform.SetParent(parent, false);
            var canvas = go.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 10;
            var scaler = go.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920, 1080);
            scaler.matchWidthOrHeight = 1f;

            if (UnityEngine.Object.FindAnyObjectByType<EventSystem>() == null)
            {
                var es = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
                es.transform.SetParent(parent, false);
            }
            return canvas;
        }

        public static RectTransform Rect(string name, Transform parent, Vector2 anchorMin, Vector2 anchorMax, Vector2 pos, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = anchorMin;
            rt.anchorMax = anchorMax;
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
            return rt;
        }

        public static RectTransform Stretch(string name, Transform parent)
        {
            var rt = Rect(name, parent, Vector2.zero, Vector2.one, Vector2.zero, Vector2.zero);
            return rt;
        }

        public static Image Panel(Transform parent, Vector2 anchor, Vector2 pos, Vector2 size, Color color)
        {
            var rt = Rect("Panel", parent, anchor, anchor, pos, size);
            var img = rt.gameObject.AddComponent<Image>();
            img.sprite = Rounded;
            img.type = Image.Type.Sliced;
            img.color = color;
            return img;
        }

        public static Image Fill(Transform parent, Color color)
        {
            var rt = Stretch("Fill", parent);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = color;
            return img;
        }

        public static Text Label(Transform parent, string text, int size, Vector2 anchor, Vector2 pos, Vector2 box,
            TextAnchor align = TextAnchor.MiddleCenter, Color? color = null, bool shadow = true)
        {
            var rt = Rect("Text", parent, anchor, anchor, pos, box);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = Font;
            t.text = text;
            t.fontSize = size;
            t.fontStyle = FontStyle.Bold;
            t.alignment = align;
            t.color = color ?? Color.white;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            if (shadow)
            {
                var sh = rt.gameObject.AddComponent<Shadow>();
                sh.effectColor = new Color(0, 0, 0, 0.6f);
                sh.effectDistance = new Vector2(3, -3);
            }
            return t;
        }

        public static Button Button(Transform parent, string text, Vector2 anchor, Vector2 pos, Vector2 size, Color color,
            Action onClick, int fontSize = 44)
        {
            var img = Panel(parent, anchor, pos, size, color);
            img.name = "Button";
            var outline = img.gameObject.AddComponent<Outline>();
            outline.effectColor = new Color(0, 0, 0, 0.35f);
            outline.effectDistance = new Vector2(0, -6);
            var b = img.gameObject.AddComponent<Button>();
            var colors = b.colors;
            colors.pressedColor = new Color(0.8f, 0.8f, 0.8f);
            colors.highlightedColor = Color.white;
            colors.selectedColor = Color.white;
            b.colors = colors;
            b.onClick.AddListener(() => onClick?.Invoke());
            var label = Label(img.transform, text, fontSize, new Vector2(0.5f, 0.5f), Vector2.zero, size);
            label.name = "Label";
            return b;
        }

        public static void SetText(Button b, string text)
        {
            var t = b.GetComponentInChildren<Text>();
            if (t != null) t.text = text;
        }

        /// <summary>Basılı tutulan buton (gaz, fren, direksiyon).</summary>
        public static HoldButton Hold(Transform parent, string text, Vector2 anchor, Vector2 pos, Vector2 size, Color color, int fontSize = 60)
        {
            var img = Panel(parent, anchor, pos, size, color);
            img.name = "Hold";
            var hb = img.gameObject.AddComponent<HoldButton>();
            Label(img.transform, text, fontSize, new Vector2(0.5f, 0.5f), Vector2.zero, size);
            return hb;
        }
    }

    /// <summary>Basılı tutma durumunu bildiren dokunmatik buton (çoklu dokunmaya uygun).</summary>
    // Not: parmak butondan kaysa bile OnPointerUp basılan nesneye gelir; bu yüzden
    // yalnızca down/up sayılır (exit'te azaltmak çift düşüşe yol açar).
    public sealed class HoldButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
    {
        int pointers;
        Image image;
        Color baseColor;

        public bool Held => pointers > 0;

        void Awake()
        {
            image = GetComponent<Image>();
            baseColor = image != null ? image.color : Color.white;
        }

        public void OnPointerDown(PointerEventData e) { pointers++; Refresh(); }
        public void OnPointerUp(PointerEventData e) { pointers = Mathf.Max(0, pointers - 1); Refresh(); }

        void OnDisable() { pointers = 0; Refresh(); }

        void Refresh()
        {
            if (image == null) return;
            image.color = Held ? new Color(baseColor.r * 1.25f, baseColor.g * 1.25f, baseColor.b * 1.25f, Mathf.Min(1f, baseColor.a + 0.25f)) : baseColor;
        }
    }
}
