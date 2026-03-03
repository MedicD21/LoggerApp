from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Resources" / "Assets.xcassets"
APP_ICON = ASSETS / "AppIcon.appiconset"
BRAND_MARK = ASSETS / "BrandMark.imageset"


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(lerp(a, b, t)) for a, b in zip(c1, c2))


def vertical_gradient(size: int, top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    for y in range(size):
        color = mix(top, bottom, y / max(size - 1, 1))
        for x in range(size):
            pixels[x, y] = (*color, 255)
    return image


def radial_glow(size: int, center: tuple[float, float], radius: float, color: tuple[int, int, int], alpha: int) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx = center[0] * size
    cy = center[1] * size
    r = radius * size
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(radius=size * 0.08))


def arc_layer(size: int, bbox_scale: float, start: int, end: int, color: tuple[int, int, int], width_scale: float) -> Image.Image:
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    margin = size * (1 - bbox_scale) / 2
    draw.arc(
        (margin, margin, size - margin, size - margin),
        start=start,
        end=end,
        fill=(*color, 255),
        width=int(size * width_scale),
    )
    return layer


def draw_brand_symbol(base: Image.Image, transparent_background: bool = False) -> Image.Image:
    size = base.width
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0) if transparent_background else (0, 0, 0, 255))

    if not transparent_background:
        canvas.alpha_composite(base)
        canvas.alpha_composite(radial_glow(size, (0.30, 0.22), 0.30, (33, 199, 156), 80))
        canvas.alpha_composite(radial_glow(size, (0.78, 0.78), 0.24, (97, 199, 237), 54))
        canvas.alpha_composite(radial_glow(size, (0.80, 0.22), 0.18, (245, 186, 76), 48))

    # Outer macro rings
    canvas.alpha_composite(arc_layer(size, 0.72, 210, 335, (33, 199, 156), 0.055))
    canvas.alpha_composite(arc_layer(size, 0.72, 12, 102, (245, 186, 76), 0.055))
    canvas.alpha_composite(arc_layer(size, 0.72, 118, 186, (97, 199, 237), 0.055))

    # Inner glass core
    core = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(core)
    core_margin = size * 0.28
    d.ellipse(
        (core_margin, core_margin, size - core_margin, size - core_margin),
        fill=(18, 23, 31, 222),
        outline=(255, 255, 255, 22),
        width=max(2, int(size * 0.006)),
    )
    core = core.filter(ImageFilter.GaussianBlur(radius=size * 0.002))
    canvas.alpha_composite(core)

    # Capsule body
    capsule = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(capsule)
    left = size * 0.40
    top = size * 0.30
    right = size * 0.60
    bottom = size * 0.68
    radius = (right - left) / 2
    d.rounded_rectangle((left, top, right, bottom), radius=radius, fill=(33, 199, 156, 255))
    mid_y = (top + bottom) / 2
    d.rounded_rectangle((left, mid_y - size * 0.008, right, bottom), radius=radius, fill=(245, 186, 76, 255))
    d.line((left, mid_y, right, mid_y), fill=(255, 255, 255, 74), width=max(2, int(size * 0.008)))
    canvas.alpha_composite(capsule)

    # Leaf cut through the capsule
    leaf = Image.new("L", (size, size), 0)
    ld = ImageDraw.Draw(leaf)
    leaf_points = [
        (size * 0.46, size * 0.34),
        (size * 0.60, size * 0.25),
        (size * 0.58, size * 0.49),
        (size * 0.43, size * 0.45),
    ]
    ld.polygon(leaf_points, fill=255)
    leaf = leaf.filter(ImageFilter.GaussianBlur(radius=size * 0.008))

    hole = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hd = ImageDraw.Draw(hole)
    hd.rectangle((0, 0, size, size), fill=(0, 0, 0, 0))
    hd.bitmap((0, 0), leaf, fill=(10, 14, 20, 235 if not transparent_background else 0))
    canvas = Image.composite(canvas, Image.new("RGBA", (size, size), (0, 0, 0, 0)), ImageChops.invert(leaf))
    if not transparent_background:
        hole_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        hole_layer.paste((10, 14, 20, 235), mask=leaf)
        canvas.alpha_composite(hole_layer)

    # Uptrend stroke
    line = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ld = ImageDraw.Draw(line)
    points = [
        (size * 0.37, size * 0.62),
        (size * 0.46, size * 0.53),
        (size * 0.52, size * 0.57),
        (size * 0.64, size * 0.43),
    ]
    ld.line(points, fill=(238, 244, 252, 255), width=max(3, int(size * 0.016)), joint="curve")
    ld.polygon(
        [
            (size * 0.64, size * 0.43),
            (size * 0.61, size * 0.44),
            (size * 0.62, size * 0.47),
            (size * 0.68, size * 0.44),
        ],
        fill=(238, 244, 252, 255),
    )
    canvas.alpha_composite(line)

    # Top highlight
    if not transparent_background:
        highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        hd = ImageDraw.Draw(highlight)
        hd.rounded_rectangle(
            (size * 0.18, size * 0.12, size * 0.82, size * 0.26),
            radius=size * 0.06,
            fill=(255, 255, 255, 26),
        )
        canvas.alpha_composite(highlight.filter(ImageFilter.GaussianBlur(radius=size * 0.04)))

    return canvas


def save_icon_set() -> None:
    APP_ICON.mkdir(parents=True, exist_ok=True)
    base = vertical_gradient(1024, (9, 11, 16), (19, 25, 34))
    icon = draw_brand_symbol(base)

    specs = [
        ("Icon-20@2x.png", 40),
        ("Icon-20@3x.png", 60),
        ("Icon-29@2x.png", 58),
        ("Icon-29@3x.png", 87),
        ("Icon-40@1x.png", 40),
        ("Icon-40@2x.png", 80),
        ("Icon-40@3x.png", 120),
        ("Icon-60@2x.png", 120),
        ("Icon-60@3x.png", 180),
        ("Icon-76@1x.png", 76),
        ("Icon-76@2x.png", 152),
        ("Icon-83.5@2x.png", 167),
        ("Icon-Marketing.png", 1024),
    ]

    for filename, size in specs:
        icon.resize((size, size), Image.Resampling.LANCZOS).save(APP_ICON / filename)

    contents = {
        "images": [
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-20@2x.png", "scale": "2x"},
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-20@3x.png", "scale": "3x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-29@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-29@3x.png", "scale": "3x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-40@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-40@3x.png", "scale": "3x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-60@2x.png", "scale": "2x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-60@3x.png", "scale": "3x"},
            {"size": "20x20", "idiom": "ipad", "filename": "Icon-20@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "ipad", "filename": "Icon-29@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-40@1x.png", "scale": "1x"},
            {"size": "40x40", "idiom": "ipad", "filename": "Icon-40@2x.png", "scale": "2x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-76@1x.png", "scale": "1x"},
            {"size": "76x76", "idiom": "ipad", "filename": "Icon-76@2x.png", "scale": "2x"},
            {"size": "83.5x83.5", "idiom": "ipad", "filename": "Icon-83.5@2x.png", "scale": "2x"},
            {"size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-Marketing.png", "scale": "1x"},
        ],
        "info": {"version": 1, "author": "xcode"},
    }
    (APP_ICON / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def save_brand_mark() -> None:
    BRAND_MARK.mkdir(parents=True, exist_ok=True)
    transparent = draw_brand_symbol(Image.new("RGBA", (1024, 1024), (0, 0, 0, 0)), transparent_background=True)
    files = [
        ("BrandMark.png", 512, "1x"),
        ("BrandMark@2x.png", 1024, "2x"),
        ("BrandMark@3x.png", 1536, "3x"),
    ]

    for filename, size, _ in files:
        transparent.resize((size, size), Image.Resampling.LANCZOS).save(BRAND_MARK / filename)

    contents = {
        "images": [
            {"idiom": "universal", "filename": "BrandMark.png", "scale": "1x"},
            {"idiom": "universal", "filename": "BrandMark@2x.png", "scale": "2x"},
            {"idiom": "universal", "filename": "BrandMark@3x.png", "scale": "3x"},
        ],
        "info": {"version": 1, "author": "xcode"},
    }
    (BRAND_MARK / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")


def main() -> None:
    save_icon_set()
    save_brand_mark()


if __name__ == "__main__":
    main()
