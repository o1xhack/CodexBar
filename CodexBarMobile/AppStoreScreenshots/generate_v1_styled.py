from __future__ import annotations

import math
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parent
INPUT_DIR = ROOT / "v1-screenshot"
OUTPUT_DIR = ROOT / "v1-styled"
EN_OUTPUT_DIR = ROOT / "v1-styled-en"
TEMP_DIR = Path(tempfile.gettempdir()) / "codexbar_screenshot_cache"

CANVAS_WIDTH = 1284
CANVAS_HEIGHT = 2778

TITLE_FONT = "/System/Library/Fonts/Hiragino Sans GB.ttc"
BODY_FONT = "/System/Library/Fonts/STHeiti Light.ttc"
BODY_FONT_BOLD = "/System/Library/Fonts/STHeiti Medium.ttc"
EN_TITLE_FONT = "/System/Library/Fonts/HelveticaNeue.ttc"
EN_BODY_FONT = "/System/Library/Fonts/HelveticaNeue.ttc"


@dataclass(frozen=True)
class SlideConfig:
    source_name: str
    output_name: str
    title: str
    subtitle: str
    accent: tuple[int, int, int]
    accent_2: tuple[int, int, int]


ZH_SLIDES = [
    SlideConfig(
        source_name="IMG_5510.HEIC",
        output_name="01-overview.png",
        title="统一查看\nAI 使用情况",
        subtitle="Claude、Gemini 与 Codex 成本占比，一眼看清",
        accent=(252, 220, 205),
        accent_2=(213, 232, 255),
    ),
    SlideConfig(
        source_name="IMG_5511.HEIC",
        output_name="02-cost-overview.png",
        title="按日按月\n追踪成本",
        subtitle="总花费、Provider Share 与概览，都在一页里",
        accent=(248, 219, 206),
        accent_2=(222, 227, 255),
    ),
    SlideConfig(
        source_name="IMG_5512.HEIC",
        output_name="03-daily-spend.png",
        title="每日趋势\n清楚可见",
        subtitle="哪天花得最多，打开就能看到",
        accent=(242, 224, 212),
        accent_2=(210, 233, 255),
    ),
    SlideConfig(
        source_name="IMG_5513.HEIC",
        output_name="04-model-mix.png",
        title="模型构成\n拆分到明细",
        subtitle="每个模型花了多少，随手就能查",
        accent=(238, 220, 231),
        accent_2=(214, 231, 255),
    ),
]

EN_SLIDES = [
    SlideConfig(
        source_name="IMG_5510.HEIC",
        output_name="01-overview.png",
        title="See All Your\nAI Usage",
        subtitle="Claude, Gemini, and Codex costs in one glance",
        accent=(252, 220, 205),
        accent_2=(213, 232, 255),
    ),
    SlideConfig(
        source_name="IMG_5511.HEIC",
        output_name="02-cost-overview.png",
        title="Track Costs\nDaily and Monthly",
        subtitle="Totals, provider share, and overview on one screen",
        accent=(248, 219, 206),
        accent_2=(222, 227, 255),
    ),
    SlideConfig(
        source_name="IMG_5512.HEIC",
        output_name="03-daily-spend.png",
        title="Daily Trends\nAt a Glance",
        subtitle="Spot your highest-spend days the moment you open it",
        accent=(242, 224, 212),
        accent_2=(210, 233, 255),
    ),
    SlideConfig(
        source_name="IMG_5513.HEIC",
        output_name="04-model-mix.png",
        title="Model Mix\nBroken Down",
        subtitle="See exactly how much each model costs",
        accent=(238, 220, 231),
        accent_2=(214, 231, 255),
    ),
]


def ensure_output_dirs() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    EN_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    TEMP_DIR.mkdir(parents=True, exist_ok=True)


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def raster_path(path: Path) -> Path:
    if path.suffix.lower() not in {".heic", ".heif"}:
        return path
    out_path = TEMP_DIR / f"{path.stem}.png"
    subprocess.run(
        ["sips", "-s", "format", "png", str(path), "--out", str(out_path)],
        check=True,
        capture_output=True,
    )
    return out_path


def fit_cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (math.ceil(image.width * scale), math.ceil(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def add_shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int, opacity: int) -> None:
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(box, radius=radius, fill=(20, 20, 40, opacity))
    blurred = shadow.filter(ImageFilter.GaussianBlur(34))
    base.alpha_composite(blurred)


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    center_x: int,
    top_y: int,
    spacing: int = 0,
) -> int:
    bbox = draw.multiline_textbbox((0, 0), text, font=font, spacing=spacing, align="center")
    x = center_x - (bbox[2] - bbox[0]) / 2
    draw.multiline_text((x, top_y), text, font=font, fill=fill, spacing=spacing, align="center")
    return int(top_y + (bbox[3] - bbox[1]))


def create_background(accent: tuple[int, int, int], accent_2: tuple[int, int, int]) -> Image.Image:
    bg = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (242, 245, 250, 255))
    gradient = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    pixels = gradient.load()
    for y in range(CANVAS_HEIGHT):
        t = y / CANVAS_HEIGHT
        color = (
            int(245 - 4 * t),
            int(247 - 2 * t),
            int(251 - 1 * t),
            255,
        )
        for x in range(CANVAS_WIDTH):
            pixels[x, y] = color
    bg.alpha_composite(gradient)

    blobs = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (0, 0, 0, 0))
    draw = ImageDraw.Draw(blobs)
    draw.ellipse((-140, -80, 760, 840), fill=accent + (145,))
    draw.ellipse((650, -120, 1490, 780), fill=accent_2 + (155,))
    draw.ellipse((160, 520, 1180, 1600), fill=(236, 237, 242, 215))
    draw.ellipse((120, 1540, 1230, 2810), fill=(230, 235, 245, 120))
    blobs = blobs.filter(ImageFilter.GaussianBlur(120))
    bg.alpha_composite(blobs)

    haze = Image.new("RGBA", (CANVAS_WIDTH, CANVAS_HEIGHT), (255, 255, 255, 0))
    haze_draw = ImageDraw.Draw(haze)
    haze_draw.rectangle((0, 0, CANVAS_WIDTH, CANVAS_HEIGHT), fill=(255, 255, 255, 68))
    haze = haze.filter(ImageFilter.GaussianBlur(20))
    bg.alpha_composite(haze)
    return bg


def phone_mockup(screenshot: Image.Image) -> Image.Image:
    outer_w = 920
    outer_h = 1998
    bezel = 16
    radius = 122
    screen_size = (outer_w - bezel * 2, outer_h - bezel * 2)
    screen_radius = 106

    mock = Image.new("RGBA", (outer_w + 120, outer_h + 120), (0, 0, 0, 0))
    add_shadow(mock, (60, 68, 60 + outer_w, 68 + outer_h), radius=120, opacity=72)
    draw = ImageDraw.Draw(mock)

    body_box = (60, 60, 60 + outer_w, 60 + outer_h)
    draw.rounded_rectangle(body_box, radius=radius, fill=(20, 22, 28, 255))
    draw.rounded_rectangle(
        (body_box[0] + 6, body_box[1] + 6, body_box[2] - 6, body_box[3] - 6),
        radius=radius - 6,
        outline=(76, 81, 92, 255),
        width=3,
    )

    screen = fit_cover(screenshot, screen_size)
    mask = rounded_mask(screen_size, screen_radius)
    screen_layer = Image.new("RGBA", mock.size, (0, 0, 0, 0))
    screen_rgba = screen.convert("RGBA")
    screen_layer.paste(screen_rgba, (60 + bezel, 60 + bezel), mask=mask)
    mock.alpha_composite(screen_layer)
    return mock


def create_standard_slide(config: SlideConfig, *, english: bool = False) -> Image.Image:
    raster = raster_path(INPUT_DIR / config.source_name)
    screenshot = Image.open(raster).convert("RGB")
    canvas = create_background(config.accent, config.accent_2)
    draw = ImageDraw.Draw(canvas)

    title_font_path = EN_TITLE_FONT if english else TITLE_FONT
    subtitle_font_path = EN_BODY_FONT if english else BODY_FONT
    title_size = 118 if english else 136
    subtitle_size = 48 if english else 54
    title_top = 184 if english else 178
    title_spacing = 0 if english else 6
    subtitle_gap = 52 if english else 58

    title_font = load_font(title_font_path, title_size)
    subtitle_font = load_font(subtitle_font_path, subtitle_size)
    title_bottom = draw_centered_text(
        draw,
        config.title,
        title_font,
        (20, 22, 32),
        CANVAS_WIDTH // 2,
        title_top,
        spacing=title_spacing,
    )
    draw_centered_text(
        draw,
        config.subtitle,
        subtitle_font,
        (108, 120, 145),
        CANVAS_WIDTH // 2,
        title_bottom + subtitle_gap,
        spacing=4,
    )

    mock = phone_mockup(screenshot)
    x = (CANVAS_WIDTH - mock.width) // 2
    y = CANVAS_HEIGHT - mock.height - 56
    canvas.alpha_composite(mock, (x, y))
    return canvas


def trim_share(image: Image.Image) -> Image.Image:
    background = Image.new(image.mode, image.size, image.getpixel((0, 0)))
    diff = ImageChops.difference(image, background)
    bbox = diff.getbbox()
    if bbox is None:
        return image
    padded = (
        max(0, bbox[0] - 24),
        max(0, bbox[1] - 24),
        min(image.width, bbox[2] + 24),
        min(image.height, bbox[3] + 24),
    )
    return image.crop(padded)


def build_share_card(image: Image.Image, width: int, angle: float) -> Image.Image:
    card = trim_share(image.convert("RGB"))
    frame_height = 1220
    inset_x = 36
    inset_y = 36
    fitted = ImageOps.contain(card, (width - inset_x * 2, frame_height - inset_y * 2))
    frame = Image.new("RGBA", (width, frame_height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    draw.rounded_rectangle((0, 0, frame.width, frame.height), radius=64, fill=(255, 255, 255, 242))
    inner = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    mask = rounded_mask((fitted.width, fitted.height), 40)
    inner.paste(
        fitted.convert("RGBA"),
        ((frame.width - fitted.width) // 2, (frame.height - fitted.height) // 2),
        mask=mask,
    )
    frame.alpha_composite(inner)
    shadowed = Image.new("RGBA", (frame.width + 160, frame.height + 160), (0, 0, 0, 0))
    add_shadow(shadowed, (80, 90, 80 + frame.width, 90 + frame.height), radius=64, opacity=76)
    shadowed.alpha_composite(frame, (80, 80))
    return shadowed.rotate(angle, resample=Image.Resampling.BICUBIC, expand=True)


def create_share_slide(*, english: bool = False) -> Image.Image:
    share_1 = Image.open(INPUT_DIR / "IMG_5514.JPG").convert("RGB")
    share_2 = Image.open(INPUT_DIR / "IMG_5515.JPG").convert("RGB")

    canvas = create_background((219, 238, 248), (233, 224, 243))
    draw = ImageDraw.Draw(canvas)
    title_font = load_font(EN_TITLE_FONT if english else TITLE_FONT, 108 if english else 128)
    subtitle_font = load_font(EN_BODY_FONT if english else BODY_FONT, 48 if english else 54)
    share_title = "Did You Vibe Today?" if english else "今天你 Vibe 了吗"
    share_subtitle = (
        "Share today's results and your 30-day trend instantly"
        if english
        else "把今日战绩和 30 天趋势，直接分享出去"
    )

    title_bottom = draw_centered_text(
        draw,
        share_title,
        title_font,
        (20, 22, 32),
        CANVAS_WIDTH // 2,
        204 if english else 194,
        spacing=4,
    )
    draw_centered_text(
        draw,
        share_subtitle,
        subtitle_font,
        (108, 120, 145),
        CANVAS_WIDTH // 2,
        title_bottom + (40 if english else 44),
        spacing=4,
    )

    upper_right_card = build_share_card(share_1, width=860, angle=6.5)
    lower_left_card = build_share_card(share_2, width=860, angle=-7.5)

    # Arrange the two cards diagonally: one anchored upper-right, one lower-left,
    # with only a partial overlap so the combined block reads closer to the phone
    # mockup scale used on the other slides.
    upper_right_x = 175
    upper_right_y = 620
    lower_left_x = 20
    lower_left_y = 1240
    canvas.alpha_composite(upper_right_card, (upper_right_x, upper_right_y))
    canvas.alpha_composite(lower_left_card, (lower_left_x, lower_left_y))
    return canvas


def main() -> None:
    ensure_output_dirs()
    for slide in ZH_SLIDES:
        image = create_standard_slide(slide, english=False)
        image.save(OUTPUT_DIR / slide.output_name)
    create_share_slide(english=False).save(OUTPUT_DIR / "05-share-cards.png")

    for slide in EN_SLIDES:
        image = create_standard_slide(slide, english=True)
        image.save(EN_OUTPUT_DIR / slide.output_name)
    create_share_slide(english=True).save(EN_OUTPUT_DIR / "05-share-cards.png")


if __name__ == "__main__":
    main()
