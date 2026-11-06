"""Package the approved Track Calo artwork for Android launcher densities.

Requires Pillow. Run from any working directory. The original AI artwork stays
untouched; these exports only resize and add adaptive-icon safety padding.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/track-calo-icon.png"
RES = ROOT / "android/app/src/main/res"

with Image.open(SOURCE) as original:
    artwork = original.convert("RGB")
    # Match the artwork's background around the padded adaptive foreground.
    background = artwork.getpixel((0, 0))
    for density, factor in (
        ("mdpi", 1),
        ("hdpi", 1.5),
        ("xhdpi", 2),
        ("xxhdpi", 3),
        ("xxxhdpi", 4),
    ):
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        legacy_size = round(48 * factor)
        artwork.resize((legacy_size, legacy_size), Image.Resampling.LANCZOS).save(
            folder / "ic_launcher.png", optimize=True
        )
        adaptive_size = round(108 * factor)
        art_size = round(adaptive_size * 0.86)
        foreground = Image.new("RGB", (adaptive_size, adaptive_size), background)
        offset = (adaptive_size - art_size) // 2
        foreground.paste(
            artwork.resize((art_size, art_size), Image.Resampling.LANCZOS),
            (offset, offset),
        )
        foreground.save(folder / "ic_launcher_foreground.png", optimize=True)
        print(f"{density}: launcher {legacy_size}px; adaptive {adaptive_size}px")
