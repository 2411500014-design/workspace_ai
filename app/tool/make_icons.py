"""Draw the Purnara mark and write every platform icon from it.

The mark: a P whose bowl is a closed ring (purna, "complete"), white on a teal
squircle with a soft top-to-bottom gradient. The same geometry is drawn in the app
by BrandMarkPainter (lib/core/widgets/common.dart); keep the two in step.

Run from app/:  python tool/make_icons.py   (needs Pillow)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

TOP = (18, 140, 130)  # #128C82, the lighter top of the tile
BOTTOM = (11, 92, 86)  # #0B5C56, the deeper bottom
SHADOW = (3, 38, 35)  # tint of the glyph's contact shadow
SS = 4  # supersampling factor
N = 5.0  # superellipse exponent: continuous corners, like platform icon shapes

ROOT = Path(__file__).resolve().parents[1]
FONTS = ROOT / "assets/fonts"


# --- geometry ------------------------------------------------------------------------


def squircle(cx: float, cy: float, r: float, steps: int = 720) -> list[tuple[float, float]]:
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s = math.cos(t), math.sin(t)
        pts.append((cx + r * math.copysign(abs(c) ** (2 / N), c), cy + r * math.copysign(abs(s) ** (2 / N), s)))
    return pts


def glyph(draw: ImageDraw.ImageDraw, ox: float, oy: float, u: float, fill) -> None:
    """The P in a 100-unit box whose top-left is (ox, oy) and unit is u pixels."""
    draw.rounded_rectangle([ox + 27.25 * u, oy + 22 * u, ox + 38.25 * u, oy + 78 * u], radius=5.5 * u, fill=fill)
    cx, cy = ox + 52.25 * u, oy + 42.5 * u
    draw.ellipse([cx - 20.5 * u, cy - 20.5 * u, cx + 20.5 * u, cy + 20.5 * u], fill=fill)


def glyph_mask(size: int, box: float, off: float) -> Image.Image:
    """Alpha mask of the white glyph (ring included) for a 100-unit box of `box` px at offset `off`."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    u = box / 100
    glyph(d, off, off, u, 255)
    cx, cy = off + 52.25 * u, off + 42.5 * u
    d.ellipse([cx - 9.5 * u, cy - 9.5 * u, cx + 9.5 * u, cy + 9.5 * u], fill=0)
    return m


# --- rendering -----------------------------------------------------------------------


def gradient(size: int) -> Image.Image:
    col = Image.new("RGBA", (1, size))
    for y in range(size):
        t = y / max(size - 1, 1)
        col.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM, strict=True)) + (255,))
    return col.resize((size, size))


def tile_layer(big: int, shape_box: float, off: float, full: bool) -> tuple[Image.Image, Image.Image]:
    """Gradient tile and its mask. `full` fills the canvas (the OS will mask it)."""
    mask = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(mask)
    if full:
        d.rectangle([0, 0, big, big], fill=255)
    else:
        half = shape_box / 2
        d.polygon(squircle(off + half, off + half, half), fill=255)
    tile = gradient(big)
    # A soft light from the top left gives the flat tile a little volume.
    glow = Image.new("L", (big, big), 0)
    ImageDraw.Draw(glow).ellipse([-0.35 * big, -0.75 * big, 0.95 * big, 0.45 * big], fill=38)
    glow = glow.filter(ImageFilter.GaussianBlur(big * 0.12))
    tile = Image.composite(Image.new("RGBA", (big, big), (255, 255, 255, 255)), tile, glow)
    out = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    out.paste(tile, (0, 0), mask)
    if not full:
        # A hairline of light along the upper rim, fading out halfway down.
        half = shape_box / 2
        rim = Image.new("L", (big, big), 0)
        ImageDraw.Draw(rim).polygon(squircle(off + half, off + half, half), fill=255)
        inner = Image.new("L", (big, big), 0)
        ImageDraw.Draw(inner).polygon(squircle(off + half, off + half + big * 0.006, half - big * 0.008), fill=255)
        rim = Image.composite(Image.new("L", (big, big), 0), rim, inner)
        fade = Image.linear_gradient("L").resize((big, big)).point(lambda v: max(0, 70 - v))
        rim = Image.composite(fade, Image.new("L", (big, big), 0), rim)
        out = Image.composite(Image.new("RGBA", (big, big), (255, 255, 255, 255)), out, rim)
    return out, mask


def icon(size: int, *, glyph_scale: float = 1.0, tile_scale: float = 1.0, full: bool = False, drop_shadow: bool = False,
         transparent_tile: bool = False) -> Image.Image:
    """glyph_scale sizes the P's 100-unit box relative to the canvas; tile_scale the tile."""
    big = size * SS
    canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    tile_box = big * tile_scale
    tile_off = (big - tile_box) / 2
    if not transparent_tile:
        tile, tile_mask = tile_layer(big, tile_box, tile_off, full)
        if drop_shadow:  # macOS icons sit on the desktop with a soft shadow
            sh = Image.new("L", (big, big), 0)
            sh.paste(tile_mask.point(lambda v: v * 0.32), (0, round(big * 0.012)))
            sh = sh.filter(ImageFilter.GaussianBlur(big * 0.018))
            canvas = Image.composite(Image.new("RGBA", (big, big), (0, 0, 0, 255)), canvas, sh)
        canvas.alpha_composite(tile)
    box = big * glyph_scale
    off = (big - box) / 2
    mark = glyph_mask(big, box, off)
    if not transparent_tile:
        contact = Image.new("L", (big, big), 0)
        contact.paste(mark.point(lambda v: v * 0.38), (0, round(box * 0.018)))
        contact = contact.filter(ImageFilter.GaussianBlur(box * 0.022))
        canvas = Image.composite(Image.new("RGBA", (big, big), SHADOW + (255,)), canvas, contact)
    canvas = Image.composite(Image.new("RGBA", (big, big), (255, 255, 255, 255)), canvas, mark)
    return canvas.resize((size, size), Image.LANCZOS)


def save(img: Image.Image, path: Path, *, opaque: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    (img.convert("RGB") if opaque else img).save(path, optimize=True)
    print(f"  {path.relative_to(ROOT)}  {img.size[0]}x{img.size[1]}")


# --- vector favicon ----------------------------------------------------------------------


def favicon_svg() -> str:
    pts = squircle(50, 50, 50, steps=160)
    d = "M" + " L".join(f"{x:.2f} {y:.2f}" for x, y in pts) + " Z"
    top = "#%02X%02X%02X" % TOP
    bottom = "#%02X%02X%02X" % BOTTOM
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100" height="100">
  <defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>
  <path d="{d}" fill="url(#g)"/>
  <rect x="27.25" y="22" width="11" height="56" rx="5.5" fill="#fff"/>
  <circle cx="52.25" cy="42.5" r="15" fill="none" stroke="#fff" stroke-width="11"/>
</svg>
"""


# --- social preview ------------------------------------------------------------------------


def wrap(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, width: int) -> list[str]:
    lines, line = [], ""
    for word in text.split():
        trial = f"{line} {word}".strip()
        if draw.textlength(trial, font=font) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    return lines + [line]


def og_image() -> Image.Image:
    """The card shown when a link to the web app is shared: the mark, the promise, and
    the real Today preview from the welcome screen (tool/og-preview.png, a 2x capture)."""
    w, h = 1200, 630
    img = Image.new("RGBA", (w, h), (246, 248, 247, 255))
    d = ImageDraw.Draw(img)
    left, column = 80, 470
    img.alpha_composite(icon(96), (left, 118))
    bold = ImageFont.truetype(str(FONTS / "PlusJakartaSans-Bold.ttf"), 58)
    headline = ImageFont.truetype(str(FONTS / "PlusJakartaSans-Bold.ttf"), 36)
    body = ImageFont.truetype(str(FONTS / "PlusJakartaSans-Regular.ttf"), 23)
    y = 236
    d.text((left, y), "Purnara", font=bold, fill=(15, 27, 26))
    y += 84
    for line in wrap(d, "Selesaikan project besarmu, satu langkah sehari.", headline, column):
        d.text((left, y), line, font=headline, fill=(15, 27, 26))
        y += 46
    y += 14
    for line in wrap(d, "Rencana dari dokumenmu, fokus harian, dan jadwal yang menyesuaikan saat keadaan berubah.", body, column):
        d.text((left, y), line, font=body, fill=(83, 98, 95))
        y += 33
    preview_path = Path(__file__).with_name("og-preview.png")
    if preview_path.exists():
        preview = Image.open(preview_path).convert("RGBA")
        pw = 560
        preview = preview.resize((pw, round(preview.height * pw / preview.width)), Image.LANCZOS)
        img.alpha_composite(preview, (w - pw - 56, (h - preview.height) // 2))
    return img


# --- outputs -------------------------------------------------------------------------------


def main() -> None:
    web = ROOT / "web"
    (web / "favicon.svg").write_text(favicon_svg(), encoding="utf-8")
    print("  web/favicon.svg")
    save(icon(64), web / "favicon.png")
    for n in (192, 512):
        save(icon(n), web / f"icons/Icon-{n}.png")
        # Maskable: full-bleed, the P inside the 80 % safe circle.
        save(icon(n, full=True, glyph_scale=0.74), web / f"icons/Icon-maskable-{n}.png")
    save(icon(180, full=True), web / "icons/apple-touch-icon.png", opaque=True)
    save(og_image(), web / "icons/og-image.png", opaque=True)

    res = ROOT / "android/app/src/main/res"
    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for folder, k in densities.items():
        # Legacy launcher icon (Android 7 and older), a little inset like system icons.
        save(icon(round(48 * k), tile_scale=0.9, glyph_scale=0.9), res / f"mipmap-{folder}/ic_launcher.png")
        # Adaptive foreground (Android 8+): 108 dp canvas, the P sized for the 72 dp visible area.
        # The background is a gradient drawable; the same layer serves themed (monochrome) icons.
        save(icon(round(108 * k), glyph_scale=0.66, transparent_tile=True), res / f"mipmap-{folder}/ic_launcher_foreground.png")

    for f in sorted((ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset").glob("*.png")):
        n = Image.open(f).size[0]
        save(icon(n, full=True), f, opaque=True)  # iOS masks corners itself; no transparency allowed

    for f in sorted((ROOT / "macos/Runner/Assets.xcassets/AppIcon.appiconset").glob("*.png")):
        n = Image.open(f).size[0]
        save(icon(n, tile_scale=0.82, glyph_scale=0.82, drop_shadow=n >= 64), f)  # macOS icon grid

    ico = ROOT / "windows/runner/resources/app_icon.ico"
    icon(256).save(ico, sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print(f"  {ico.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
