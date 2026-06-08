#!/usr/bin/env python3
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
RESOURCES = ROOT / "Resources"
ICONSET = RESOURCES / "AppIcon.iconset"
MASTER = RESOURCES / "AppIcon-1024.png"
ICNS = RESOURCES / "AppIcon.icns"


def lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient(size):
    top_left = (24, 94, 215)
    bottom_right = (15, 188, 158)
    accent = (83, 235, 255)
    img = Image.new("RGBA", (size, size))
    pixels = img.load()

    for y in range(size):
        for x in range(size):
            tx = x / (size - 1)
            ty = y / (size - 1)
            t = (tx * 0.55 + ty * 0.45)
            r = lerp(top_left[0], bottom_right[0], t)
            g = lerp(top_left[1], bottom_right[1], t)
            b = lerp(top_left[2], bottom_right[2], t)

            dx = (x - size * 0.24) / size
            dy = (y - size * 0.18) / size
            glow = max(0, 1 - math.sqrt(dx * dx + dy * dy) * 4.2)
            r = min(255, r + int(accent[0] * glow * 0.22))
            g = min(255, g + int(accent[1] * glow * 0.22))
            b = min(255, b + int(accent[2] * glow * 0.22))
            pixels[x, y] = (r, g, b, 255)

    return img


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_polyline(draw, points, fill, width):
    for a, b in zip(points, points[1:]):
        draw.line([a, b], fill=fill, width=width, joint="curve")


def draw_icon(size=1024):
    scale = size / 1024
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    margin = int(42 * scale)
    radius = int(224 * scale)
    sdraw.rounded_rectangle(
        (margin, margin + int(14 * scale), size - margin, size - margin + int(14 * scale)),
        radius=radius,
        fill=(0, 0, 0, 78),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(24 * scale)))
    canvas.alpha_composite(shadow)

    body = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = rounded_mask(size - margin * 2, radius)
    bg = gradient(size - margin * 2)
    body.paste(bg, (margin, margin), mask)

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    odraw.rounded_rectangle(
        (margin + int(22 * scale), margin + int(20 * scale), size - margin - int(22 * scale), size - margin - int(22 * scale)),
        radius=int(190 * scale),
        outline=(255, 255, 255, 44),
        width=max(1, int(5 * scale)),
    )
    odraw.ellipse(
        (int(92 * scale), int(74 * scale), int(660 * scale), int(500 * scale)),
        fill=(255, 255, 255, 34),
    )
    overlay = overlay.filter(ImageFilter.GaussianBlur(int(18 * scale)))
    body.alpha_composite(overlay)

    draw = ImageDraw.Draw(body)
    white = (255, 255, 255, 235)
    dim = (218, 250, 255, 168)
    green = (124, 255, 204, 245)

    nodes = [
        (int(324 * scale), int(352 * scale)),
        (int(668 * scale), int(336 * scale)),
        (int(512 * scale), int(638 * scale)),
    ]

    line_width = max(8, int(36 * scale))
    draw.line([nodes[0], nodes[1], nodes[2], nodes[0]], fill=dim, width=line_width, joint="curve")

    for idx, (x, y) in enumerate(nodes):
        outer = int((86 if idx != 2 else 96) * scale)
        inner = int((47 if idx != 2 else 54) * scale)
        draw.ellipse((x - outer, y - outer, x + outer, y + outer), fill=(0, 35, 78, 94))
        draw.ellipse((x - inner, y - inner, x + inner, y + inner), fill=white)
        draw.ellipse(
            (x - int(22 * scale), y - int(22 * scale), x + int(22 * scale), y + int(22 * scale)),
            fill=(29, 132, 236, 255),
        )

    bolt = [
        (int(616 * scale), int(130 * scale)),
        (int(514 * scale), int(466 * scale)),
        (int(631 * scale), int(442 * scale)),
        (int(562 * scale), int(716 * scale)),
        (int(788 * scale), int(346 * scale)),
        (int(654 * scale), int(374 * scale)),
        (int(738 * scale), int(130 * scale)),
    ]
    bolt_shadow = [(x + int(10 * scale), y + int(14 * scale)) for x, y in bolt]
    draw.polygon(bolt_shadow, fill=(0, 21, 52, 88))
    draw.polygon(bolt, fill=green)
    draw.line(bolt + [bolt[0]], fill=(255, 255, 255, 92), width=max(2, int(4 * scale)), joint="curve")

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(highlight)
    hdraw.arc(
        (int(164 * scale), int(126 * scale), int(832 * scale), int(782 * scale)),
        start=204,
        end=292,
        fill=(255, 255, 255, 120),
        width=max(2, int(10 * scale)),
    )
    body.alpha_composite(highlight)

    canvas.alpha_composite(body)
    return canvas


def main():
    RESOURCES.mkdir(exist_ok=True)
    ICONSET.mkdir(exist_ok=True)

    master = draw_icon(1024)
    master.save(MASTER)

    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }

    for name, pixel_size in sizes.items():
        resized = master.resize((pixel_size, pixel_size), Image.Resampling.LANCZOS)
        resized.save(ICONSET / name)

    print(MASTER)
    print(ICONSET)
    print(ICNS)


if __name__ == "__main__":
    main()
