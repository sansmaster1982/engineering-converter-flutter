"""Build App Store / Google Play / RuStore marketing screenshots from raw device captures.

Input : raw 1080x2316 screenshots taken with `adb exec-out screencap`
Output: framed, captioned images in screenshots_v6/<platform>/
"""

import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SRC = sys.argv[1] if len(sys.argv) > 1 else "raw_screens"
OUT = "screenshots_v6"

# device capture geometry (Samsung S23 Ultra, 1080x2316)
STATUS_BAR = 94      # rows to drop at the top (clock, battery, personal icons)
NAV_BAR = 130        # rows to drop at the bottom (system navigation)

# brand palette (matches the app's Material 3 seed #3F6FD8)
BG_TOP = (30, 44, 86)
BG_BOTTOM = (54, 92, 174)
TITLE = (255, 255, 255)
SUBTITLE = (186, 205, 246)
FRAME = (12, 20, 44)

SLIDES = [
    ("01_conv",        "Бары, кгс/см², psi\nбез поиска в браузере", "Перевод сразу во все единицы категории"),
    ("02_calcs",       "Пять расчётов ОВиК\nв одном приложении",    "Скорость, мощность, клапан, бак, изоляция"),
    ("03_velocity",    "Скорость потока\nпо всем диаметрам сразу",  "Сталь, PP-R, PEX, медь — реальные диаметры"),
    ("04_power",       "Тепловая мощность\nи расход в обе стороны", "Вода и гликоли, свойства по температуре"),
    ("05_tank",        "Расширительный бак\nза один ввод",          "Требуемый объём и стандартный типоразмер"),
    ("06_insulation",  "Изоляция труб\nсразу для сметы",            "Площадь, объём и диаметр с изоляцией"),
    ("07_dark",        "Тёмная тема,\nрусский и английский",        "Офлайн, без рекламы и без регистрации"),
]

# output canvases: name -> (width, height)
CANVASES = {
    "android": (1080, 1920),   # Google Play / RuStore phone
    "ios_67": (1290, 2796),    # App Store 6.7" iPhone
}


def font(size, bold=True):
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    try:
        return ImageFont.truetype(name, size)
    except OSError:
        return ImageFont.truetype("arialbd.ttf" if bold else "arial.ttf", size)


def gradient(size):
    w, h = size
    grad = Image.new("RGB", (1, h))
    px = grad.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        px[0, y] = tuple(round(a + (b - a) * t) for a, b in zip(BG_TOP, BG_BOTTOM))
    img = grad.resize((w, h), Image.BILINEAR)
    # soft light spot in the upper third
    glow = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([-w // 3, -h // 6, w + w // 3, h // 2], fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(w // 6))
    img = Image.composite(Image.new("RGB", (w, h), (92, 132, 214)), img, glow)
    return img


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def shadow(size, radius, blur, offset, alpha=120):
    w, h = size
    pad = blur * 3
    layer = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(
        [pad, pad + offset, pad + w - 1, pad + h - 1 + offset], radius, fill=(0, 0, 0, alpha)
    )
    return layer.filter(ImageFilter.GaussianBlur(blur)), pad


def wrap(draw, text, fnt, max_width):
    lines = []
    for paragraph in text.split("\n"):
        words, line = paragraph.split(), ""
        for word in words:
            probe = f"{line} {word}".strip()
            if draw.textlength(probe, font=fnt) <= max_width or not line:
                line = probe
            else:
                lines.append(line)
                line = word
        lines.append(line)
    return lines


def build(raw_path, title, subtitle, canvas_size, out_path):
    W, H = canvas_size
    scale = W / 1080

    shot = Image.open(raw_path).convert("RGB")
    shot = shot.crop((0, STATUS_BAR, shot.width, shot.height - NAV_BAR))

    canvas = gradient((W, H))
    draw = ImageDraw.Draw(canvas)

    # --- caption ---
    f_title = font(round(62 * scale), True)
    f_sub = font(round(34 * scale), False)
    margin = round(72 * scale)
    max_text = W - margin * 2

    title_lines = wrap(draw, title, f_title, max_text)
    sub_lines = wrap(draw, subtitle, f_sub, max_text)

    y = round(86 * scale)
    line_h = round(78 * scale)
    for line in title_lines:
        draw.text((margin, y), line, font=f_title, fill=TITLE)
        y += line_h
    y += round(14 * scale)
    for line in sub_lines:
        draw.text((margin, y), line, font=f_sub, fill=SUBTITLE)
        y += round(46 * scale)

    # --- device frame: identical geometry on every slide ---
    caption_block = round(H * 0.225)
    bottom_margin = round(H * 0.025)
    bezel = round(14 * scale)
    radius = round(54 * scale)

    frame_h = H - caption_block - bottom_margin
    inner_h = frame_h - bezel * 2
    inner_w = round(inner_h * shot.width / shot.height)
    frame_w = inner_w + bezel * 2
    if frame_w > W - margin * 2:                 # never wider than the safe area
        frame_w = W - margin * 2
        inner_w = frame_w - bezel * 2
        inner_h = round(inner_w * shot.height / shot.width)
        frame_h = inner_h + bezel * 2
    x = (W - frame_w) // 2
    top = caption_block

    sh, pad = shadow((frame_w, frame_h), radius, round(26 * scale), round(18 * scale))
    canvas.paste(Image.new("RGB", sh.size, (0, 0, 0)), (x - pad, top - pad), sh)

    frame = Image.new("RGB", (frame_w, frame_h), FRAME)
    frame.paste(shot.resize((inner_w, inner_h), Image.LANCZOS), (bezel, bezel))
    canvas.paste(rounded(frame, radius), (x, top), rounded(frame, radius))

    canvas.save(out_path, quality=95)
    return out_path


def main():
    made = []
    for platform, size in CANVASES.items():
        folder = os.path.join(OUT, platform)
        os.makedirs(folder, exist_ok=True)
        for index, (name, title, subtitle) in enumerate(SLIDES, start=1):
            raw = os.path.join(SRC, f"{name}.png")
            if not os.path.exists(raw):
                print(f"skip (no file): {raw}")
                continue
            out = os.path.join(folder, f"{index:02d}_{name.split('_', 1)[1]}.png")
            made.append(build(raw, title, subtitle, size, out))
    for path in made:
        print(path)
    print(f"\n{len(made)} screenshots written to {os.path.abspath(OUT)}")


if __name__ == "__main__":
    main()
