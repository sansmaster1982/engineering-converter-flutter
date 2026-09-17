"""Build the v6 app icon set from the chosen artwork.

Source: icon_source_v6.png — a blue 3D gear holding the letters E and C,
the E white and the C red, drawn as a rounded square on a white sheet.

The script trims that white sheet, rebuilds the corners with the artwork's own
background gradient (iOS icons must be opaque and square, the system rounds
them itself) and writes every size Android, iOS and the stores need.
"""

import json
import os

from PIL import Image, ImageDraw

SOURCE = "icon_source_v6.png"
MASTER = 1024
CORNER = 0.235          # corner radius of the artwork, fraction of its side

DENSITIES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def trim(img, threshold=246):
    """Crop the white sheet around the artwork and return a square image."""
    grey = img.convert("L").point(lambda v: 0 if v >= threshold else 255)
    box = grey.getbbox()
    if box is None:
        return img
    left, top, right, bottom = box
    side = max(right - left, bottom - top)
    cx, cy = (left + right) // 2, (top + bottom) // 2
    half = side // 2
    return img.crop((cx - half, cy - half, cx + half, cy + half))


def fill_corners(img):
    """Replace the transparent/white corners with the artwork's own gradient."""
    size = img.width
    inset = round(size * 0.06)
    top_color = img.getpixel((size // 2, inset))
    bottom_color = img.getpixel((size // 2, size - inset - 1))

    grad = Image.new("RGB", (1, size))
    px = grad.load()
    for y in range(size):
        t = y / max(size - 1, 1)
        px[0, y] = tuple(round(a + (b - a) * t) for a, b in zip(top_color, bottom_color))
    background = grad.resize((size, size), Image.BILINEAR)

    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, size - 1, size - 1], round(size * CORNER), fill=255)
    return Image.composite(img.convert("RGB"), background, mask)


def rounded(img, ratio=CORNER):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.width - 1, img.height - 1], round(img.width * ratio), fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def main():
    src = Image.open(SOURCE).convert("RGB")
    art = trim(src).resize((MASTER, MASTER), Image.LANCZOS)
    master = fill_corners(art)                 # opaque square, corners rebuilt

    master.save("icon_v6_1024.png")
    rounded(master.resize((512, 512), Image.LANCZOS)).save("icon_v6_512_rounded.png")
    print("icon_v6_1024.png, icon_v6_512_rounded.png")

    res = "flutter_app/android/app/src/main/res"
    if os.path.isdir(res):
        for folder, px in DENSITIES.items():
            # launcher icon keeps its own rounded corners with transparency
            rounded(master.resize((px, px), Image.LANCZOS)).save(
                f"{res}/mipmap-{folder}/ic_launcher.png")
        print(f"{res}: {len(DENSITIES)} launcher icons")

    iconset = "flutter_app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
    meta_path = os.path.join(iconset, "Contents.json")
    if os.path.exists(meta_path):
        meta = json.load(open(meta_path))
        for entry in meta["images"]:
            px = round(float(entry["size"].split("x")[0]) * int(entry["scale"].rstrip("x")))
            # App Store icons must be square and fully opaque, no alpha channel
            master.resize((px, px), Image.LANCZOS).save(os.path.join(iconset, entry["filename"]))
        print(f"{iconset}: {len(meta['images'])} sizes")


if __name__ == "__main__":
    main()
