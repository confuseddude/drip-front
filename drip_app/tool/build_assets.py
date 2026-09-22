"""Builds DRIP's theme + brand assets from the Canva poster exports.

Inputs  (repo root):  posters/poster_XX.jpg   (cropped Canva "Drip logo" pages)
Outputs (drip_app/):
  assets/themes/poster_<id>.jpg   selector artwork (560px)
  assets/themes/bg_<id>.jpg       pre-blurred, darkened ambient backdrop (192px)
  assets/brand/drip_wordmark*.svg  vector trace of the DRIP wordmark; the i-dot
                                   is the brand-red "drip" (dark / light / mono)
  assets/icon/app_icon*.png        default launcher icon sources (the default theme's poster)
  android/.../ic_theme_<id>*       per-theme launcher icons (activity-aliases)
  ios/.../AppIcon-<id>.appiconset  per-theme alternate icons

Run:  python tool/build_assets.py
Backdrops are baked offline so the app never blurs a full-screen image at
runtime (cheap to draw, no per-frame BackdropFilter cost).
"""
from pathlib import Path

import cv2
import numpy as np
from scipy.ndimage import gaussian_filter1d
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "drip_app"
POSTERS = ROOT / "posters"
THEMES = APP / "assets" / "themes"
BRAND = APP / "assets" / "brand"

# theme id -> poster page number (Canva page order)
THEME_POSTERS = {
    "retro_cyber": 4,  # default: the black / white / red / blue flare poster
    "aurora_cyan": 3,
    "vault_cream": 1,
    "indigo_marble": 5,
    "denim_stars": 7,
    "golden_hour": 8,
    "crimson_teal": 9,
    "violet_bloom": 10,
    "acid_lime": 11,
    "moss_archive": 12,
    "verdant_blur": 13,
    "oxblood_linen": 14,
    "holo_pink": 15,
}

BASE = np.array([14, 16, 24], dtype=np.float32)  # AppColors.base


def build_backdrop(im: Image.Image) -> Image.Image:
    """Blur until the wordmark dissolves, then pull luminance down so cream
    text stays readable on every theme (including the light parchment ones)."""
    small = im.resize((192, 192), Image.LANCZOS).filter(ImageFilter.GaussianBlur(14))
    a = np.asarray(small).astype(np.float32)
    # Richer colour before darkening, so pale posters (parchment, linen) keep
    # their hue instead of dropping to flat grey.
    mean = a.mean(axis=2, keepdims=True)
    a = np.clip(mean + (a - mean) * 1.55, 0, 255)
    lum = (0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2]) / 255.0
    target = 0.30
    peak = np.percentile(lum, 96)
    k = min(1.0, target / max(peak, 1e-3))
    a = a * k
    a = a * 0.78 + BASE * 0.22
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def build_themes() -> None:
    THEMES.mkdir(parents=True, exist_ok=True)
    for tid, page in THEME_POSTERS.items():
        src = Image.open(POSTERS / f"poster_{page:02d}.jpg").convert("RGB")
        src.resize((560, 560), Image.LANCZOS).save(
            THEMES / f"poster_{tid}.jpg", quality=84, optimize=True
        )
        build_backdrop(src).save(THEMES / f"bg_{tid}.jpg", quality=82)
        print("theme", tid)


def smooth(c, sigma=4.0):
    pts = c.reshape(-1, 2).astype(np.float64)
    if len(pts) < 20:
        return pts
    x = gaussian_filter1d(pts[:, 0], sigma, mode="wrap")
    y = gaussian_filter1d(pts[:, 1], sigma, mode="wrap")
    return np.stack([x, y], 1)


def poly_path(pts, ox, oy):
    return "M" + " L".join(f"{x - ox:.2f} {y - oy:.2f}" for x, y in pts) + " Z"


def trace_wordmark():
    """Trace the cream wordmark on the flat midnight poster (page 3)."""
    BRAND.mkdir(parents=True, exist_ok=True)
    im = Image.open(POSTERS / "poster_03.jpg").convert("L")
    x0, y0, x1, y1 = 140, 170, 520, 480  # wordmark only (skips the ESTD line)
    crop = im.crop((x0, y0, x1, y1))
    up = 8
    big = crop.resize((crop.width * up, crop.height * up), Image.BICUBIC)
    arr = cv2.GaussianBlur(np.asarray(big), (0, 0), 5.0)
    _, mask = cv2.threshold(arr, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    cnts, _ = cv2.findContours(mask, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    cnts = [c for c in cnts if cv2.contourArea(c) > 60 * up * up]
    cnts.sort(key=cv2.contourArea)
    dot = cnts[0]  # smallest = the i-dot
    body = cnts[1:]  # counters + the joined D-r-i-p outline
    polys = []
    for c in cnts:
        sm = smooth(c) / up
        sm = cv2.approxPolyDP(sm.astype(np.float32).reshape(-1, 1, 2), 0.06, True).reshape(-1, 2)
        polys.append(sm)
    allpts = np.vstack(polys)
    ox, oy = allpts.min(0)
    w, h = allpts.max(0) - allpts.min(0)
    dot_d = poly_path(polys[0], ox, oy)
    body_d = " ".join(poly_path(p_, ox, oy) for p_ in polys[1:])

    def svg(main, drop):
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.2f} {h:.2f}">'
            f'<path fill="{main}" fill-rule="evenodd" d="{body_d}"/>'
            f'<path fill="{drop}" d="{dot_d}"/></svg>'
        )

    (BRAND / "drip_wordmark.svg").write_text(svg("#E8DFC8", "#FF2020"))
    (BRAND / "drip_wordmark_light.svg").write_text(svg("#0E1018", "#FF2020"))
    (BRAND / "drip_wordmark_mono.svg").write_text(svg("#FFFFFF", "#FFFFFF"))
    print("wordmark", round(w, 1), round(h, 1), len(cnts), "contours")


ICON = APP / "assets" / "icon"
ANDROID_RES = APP / "android" / "app" / "src" / "main" / "res"
IOS_ASSETS = APP / "ios" / "Runner" / "Assets.xcassets"
DEFAULT_THEME = "retro_cyber"


def poster_of(tid: str) -> Image.Image:
    return Image.open(POSTERS / f"poster_{THEME_POSTERS[tid]:02d}.jpg").convert("RGB")


def icon_crop(tid: str, size: int = 1024) -> Image.Image:
    """The poster cropped around its wordmark (the small tagline is cropped
    out), so the icon reads at launcher size."""
    im = poster_of(tid)
    cx, cy, half = 329, 327, 240
    return im.crop((cx - half, cy - half, cx + half, cy + half)).resize(
        (size, size), Image.LANCZOS
    )


def rounded(im: Image.Image, frac: float = 0.22) -> Image.Image:
    """Legacy (pre-adaptive) Android icons are drawn with rounded corners."""
    from PIL import ImageDraw

    s = im.size[0]
    mask = Image.new("L", (s * 4, s * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, s * 4 - 1, s * 4 - 1), radius=int(s * 4 * frac), fill=255
    )
    out = im.convert("RGBA")
    out.putalpha(mask.resize((s, s), Image.LANCZOS))
    return out


def build_app_icons() -> None:
    """One launcher icon per theme, from that theme's poster.

    * Flutter/iOS/web default  -> assets/icon/app_icon*.png (the default theme)
    * Android                  -> an <activity-alias> per theme (see manifest):
                                  mipmap-anydpi-v26/ic_theme_<id>.xml (adaptive)
                                  mipmap-xxxhdpi/ic_theme_<id>.png    (legacy)
                                  drawable-nodpi/ic_bg_<id>.jpg       (adaptive bg)
    * iOS                      -> AppIcon-<id>.appiconset per non-default theme,
                                  listed in ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES
    """
    ICON.mkdir(parents=True, exist_ok=True)
    # Default (also feeds flutter_launcher_icons for iOS default / web / legacy).
    icon_crop(DEFAULT_THEME).save(ICON / "app_icon.png")
    poster_of(DEFAULT_THEME).resize((1024, 1024), Image.LANCZOS).save(ICON / "app_icon_bg.png")
    Image.new("RGBA", (1024, 1024), (0, 0, 0, 0)).save(ICON / "transparent.png")

    (ANDROID_RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (ANDROID_RES / "mipmap-xxxhdpi").mkdir(parents=True, exist_ok=True)
    (ANDROID_RES / "drawable-nodpi").mkdir(parents=True, exist_ok=True)

    ios_contents = (IOS_ASSETS / "AppIcon.appiconset" / "Contents.json").read_text()
    import json

    ios_images = json.loads(ios_contents)["images"]
    alt_names = []
    for tid in THEME_POSTERS:
        # ---- Android
        poster_of(tid).resize((432, 432), Image.LANCZOS).save(
            ANDROID_RES / "drawable-nodpi" / f"ic_bg_{tid}.jpg", quality=88
        )
        xml_lines = [
            '<?xml version="1.0" encoding="utf-8"?>',
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">',
            f'  <background android:drawable="@drawable/ic_bg_{tid}"/>',
            '  <foreground android:drawable="@android:color/transparent"/>',
            "</adaptive-icon>",
            "",
        ]
        (ANDROID_RES / "mipmap-anydpi-v26" / f"ic_theme_{tid}.xml").write_text(
            chr(10).join(xml_lines)
        )
        rounded(icon_crop(tid, 192)).save(ANDROID_RES / "mipmap-xxxhdpi" / f"ic_theme_{tid}.png")
        # ---- iOS (default theme is the primary AppIcon set)
        if tid == DEFAULT_THEME:
            continue
        name = "AppIcon-" + tid.replace("_", "-")
        alt_names.append(name)
        d = IOS_ASSETS / f"{name}.appiconset"
        d.mkdir(parents=True, exist_ok=True)
        (d / "Contents.json").write_text(ios_contents)
        src = icon_crop(tid, 1024)
        for img in ios_images:
            base = float(img["size"].split("x")[0])
            px = int(round(base * int(img["scale"].rstrip("x"))))
            src.resize((px, px), Image.LANCZOS).convert("RGB").save(d / img["filename"])
    print("icons:", len(THEME_POSTERS), "themes; iOS alternates:", " ".join(alt_names))


if __name__ == "__main__":
    build_themes()
    trace_wordmark()
    build_app_icons()
