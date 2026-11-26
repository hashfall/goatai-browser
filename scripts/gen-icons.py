#!/usr/bin/env python3
"""Gera os ícones do Goatai a partir de branding/icon.webp (PIL puro)."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "branding" / "icon.webp"
OUT = ROOT / "branding" / "icons"
OUT.mkdir(parents=True, exist_ok=True)

# 1) Remove o fundo branco conectado às bordas.
img = Image.open(SRC).convert("RGBA")
w, h = img.size
for xy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
    ImageDraw.floodfill(img, xy, (255, 255, 255, 0), thresh=12)

box = img.getbbox()
art = img.crop(box)
print(f"arte: {art.size} (de {img.size})")


def square(size: int, pad: float = 0.94, src: Image.Image = art) -> Image.Image:
    inner = max(1, round(size * pad))
    r = min(inner / src.width, inner / src.height)
    resized = src.resize(
        (max(1, round(src.width * r)), max(1, round(src.height * r))),
        Image.LANCZOS,
    )
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((size - resized.width) // 2, (size - resized.height) // 2),
    )
    return canvas


for s in (16, 22, 24, 32, 48, 64, 128, 256, 512):
    square(s).save(OUT / f"product_logo_{s}.png")


# 2) Wordmark 97x22 (ícone + "Goatai"), versão normal e branca.
def wordmark(color: tuple[int, int, int, int], path: Path) -> None:
    H = 22
    canvas = Image.new("RGBA", (97, H), (0, 0, 0, 0))
    icon = square(20, pad=1.0)
    canvas.alpha_composite(icon, (0, 1))
    font = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", 16)
    d = ImageDraw.Draw(canvas)
    bbox = d.textbbox((0, 0), "Goatai", font=font)
    tx, ty = 22, (H - (bbox[3] - bbox[1])) // 2 - bbox[1]
    d.text((tx, ty), "Goatai", font=font, fill=color)
    canvas.save(path)


wordmark((32, 33, 36, 255), OUT / "product_logo_name_22.png")
wordmark((255, 255, 255, 255), OUT / "product_logo_name_22_white.png")

# 3) Mono (silhueta branca) e XPM para Linux.
mono = square(22, pad=1.0)
mask = mono.split()[3]
silhouette = Image.new("RGBA", mono.size, (255, 255, 255, 255))
silhouette.putalpha(mask)
silhouette.save(OUT / "product_logo_22_mono.png")

square(32).save(OUT / "_xpm_src.png")
import subprocess

subprocess.run(
    [
        "magick",
        str(OUT / "_xpm_src.png"),
        "-background",
        "none",
        str(OUT / "product_logo_32.xpm"),
    ],
    check=True,
)
(OUT / "_xpm_src.png").unlink()

# 4) Arte para a New Tab Page (fundo transparente, 2x).
art.resize((512, round(512 * art.height / art.width)), Image.LANCZOS).save(
    OUT / "ntp_logo.png"
)

print("gerado em", OUT)
