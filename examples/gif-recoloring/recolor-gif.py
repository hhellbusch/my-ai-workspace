#!/usr/bin/env python3
"""
Recolor a red siren GIF to different colors (amber, green, blue, white).

Usage:
    python3 recolor-gif.py input.gif [--output-dir OUTPUT_DIR]

Produces: input_amber.gif, input_green.gif, input_blue.gif, input_white.gif
"""

import argparse
import colorsys
import os
from pathlib import Path

import numpy as np
from PIL import Image


COLOR_CONFIGS = {
    "amber": {"hue_shift": 25, "saturation_scale": 1.0, "value_scale": 1.0},
    "green": {"hue_shift": 120, "saturation_scale": 1.0, "value_scale": 1.0},
    "blue": {"hue_shift": 240, "saturation_scale": 1.0, "value_scale": 1.0},
    "white": {"hue_shift": 0, "saturation_scale": 0.08, "value_scale": 1.3},
}


def extract_frames(gif_path: str) -> list[dict]:
    """Extract all frames from a GIF with their metadata."""
    img = Image.open(gif_path)
    frames = []
    try:
        while True:
            frame_data = {
                "image": img.copy().convert("RGBA"),
                "duration": img.info.get("duration", 100),
            }
            frames.append(frame_data)
            img.seek(img.tell() + 1)
    except EOFError:
        pass
    return frames


def recolor_frame(frame: Image.Image, color_config: dict) -> Image.Image:
    """Shift hue of a single RGBA frame."""
    arr = np.array(frame, dtype=np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]

    h = np.zeros(rgb.shape[:2])
    s = np.zeros(rgb.shape[:2])
    v = np.zeros(rgb.shape[:2])
    for y in range(rgb.shape[0]):
        for x in range(rgb.shape[1]):
            h[y, x], s[y, x], v[y, x] = colorsys.rgb_to_hsv(
                rgb[y, x, 0], rgb[y, x, 1], rgb[y, x, 2]
            )

    hue_shift = color_config["hue_shift"]
    sat_scale = color_config["saturation_scale"]
    val_scale = color_config["value_scale"]

    # Detect reddish pixels: hue near 0 or near 1 (wraps around), with some saturation
    is_red = ((h < 0.10) | (h > 0.83)) & (s > 0.05)

    if hue_shift > 0 and sat_scale >= 1.0:
        h[is_red] = (hue_shift / 360.0) % 1.0
    # Apply saturation and value scaling to colored (red) regions
    s[is_red] = np.clip(s[is_red] * sat_scale, 0, 1)
    v[is_red] = np.clip(v[is_red] * val_scale, 0, 1)

    new_rgb = np.zeros_like(rgb)
    for y in range(rgb.shape[0]):
        for x in range(rgb.shape[1]):
            r, g, b = colorsys.hsv_to_rgb(h[y, x], s[y, x], v[y, x])
            new_rgb[y, x] = [r, g, b]

    result = np.zeros_like(arr, dtype=np.uint8)
    result[:, :, :3] = (new_rgb * 255).astype(np.uint8)
    result[:, :, 3] = alpha.astype(np.uint8)
    return Image.fromarray(result)


def recolor_frame_fast(frame: Image.Image, color_config: dict) -> Image.Image:
    """Vectorized hue shift of a single RGBA frame (much faster)."""
    arr = np.array(frame, dtype=np.float64)
    rgb = arr[:, :, :3] / 255.0
    alpha = arr[:, :, 3]

    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]

    # Vectorized RGB -> HSV
    cmax = np.maximum(np.maximum(r, g), b)
    cmin = np.minimum(np.minimum(r, g), b)
    delta = cmax - cmin
    safe_delta = np.where(delta > 0, delta, 1.0)

    # Hue
    h = np.zeros_like(cmax)
    mask_r = (cmax == r) & (delta > 0)
    mask_g = (cmax == g) & (delta > 0)
    mask_b = (cmax == b) & (delta > 0)
    h[mask_r] = (((g[mask_r] - b[mask_r]) / safe_delta[mask_r]) % 6) / 6
    h[mask_g] = (((b[mask_g] - r[mask_g]) / safe_delta[mask_g]) + 2) / 6
    h[mask_b] = (((r[mask_b] - g[mask_b]) / safe_delta[mask_b]) + 4) / 6

    # Saturation
    safe_cmax = np.where(cmax > 0, cmax, 1.0)
    s = np.where(cmax > 0, delta / safe_cmax, 0)

    # Value
    v = cmax

    hue_shift = color_config["hue_shift"]
    sat_scale = color_config["saturation_scale"]
    val_scale = color_config["value_scale"]

    is_red = ((h < 0.10) | (h > 0.83)) & (s > 0.05)

    if hue_shift > 0 and sat_scale >= 1.0:
        h[is_red] = (hue_shift / 360.0) % 1.0
    s[is_red] = np.clip(s[is_red] * sat_scale, 0, 1)
    v[is_red] = np.clip(v[is_red] * val_scale, 0, 1)

    # Vectorized HSV -> RGB
    h6 = h * 6.0
    i = np.floor(h6).astype(int) % 6
    f = h6 - np.floor(h6)
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)

    new_r = np.zeros_like(v)
    new_g = np.zeros_like(v)
    new_b = np.zeros_like(v)

    for idx, (rv, gv, bv) in enumerate(
        [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)]
    ):
        mask = i == idx
        new_r[mask] = rv[mask]
        new_g[mask] = gv[mask]
        new_b[mask] = bv[mask]

    result = np.zeros((*rgb.shape[:2], 4), dtype=np.uint8)
    result[:, :, 0] = (np.clip(new_r, 0, 1) * 255).astype(np.uint8)
    result[:, :, 1] = (np.clip(new_g, 0, 1) * 255).astype(np.uint8)
    result[:, :, 2] = (np.clip(new_b, 0, 1) * 255).astype(np.uint8)
    result[:, :, 3] = alpha.astype(np.uint8)
    return Image.fromarray(result)


TRANSPARENT_KEY = (0, 255, 0)


def build_shared_palette(rgba_frames: list[Image.Image]) -> tuple[list[int], int]:
    """Build a single shared palette from all frames with a reserved transparency slot.

    Returns (palette_flat_list, transparency_index).
    """
    # Composite all frames into one tall image so quantization sees all colors
    w, h = rgba_frames[0].size
    composite = Image.new("RGB", (w, h * len(rgba_frames)))
    for i, f in enumerate(rgba_frames):
        arr = np.array(f)
        alpha = arr[:, :, 3]
        rgb_arr = arr[:, :, :3].copy()
        rgb_arr[alpha < 128] = TRANSPARENT_KEY
        composite.paste(Image.fromarray(rgb_arr), (0, i * h))

    quantized = composite.quantize(colors=255, method=Image.Quantize.MEDIANCUT)
    palette = quantized.getpalette()[:255 * 3]

    # Append the key color as the last palette entry (index 255) for transparency
    trans_index = 255
    palette += list(TRANSPARENT_KEY)
    # Pad to full 256*3 if needed
    palette += [0] * (256 * 3 - len(palette))

    return palette, trans_index


def rgba_to_gif_frame(
    frame: Image.Image, palette_img: Image.Image, trans_index: int
) -> Image.Image:
    """Map an RGBA frame to a shared palette with proper transparency."""
    arr = np.array(frame)
    alpha = arr[:, :, 3]
    transparent_mask = alpha < 128

    rgb_arr = arr[:, :, :3].copy()
    rgb_arr[transparent_mask] = TRANSPARENT_KEY
    rgb_frame = Image.fromarray(rgb_arr)

    # Quantize using the shared palette
    mapped = rgb_frame.quantize(palette=palette_img, dither=Image.Dither.FLOYDSTEINBERG)
    mapped_arr = np.array(mapped)

    # Force all transparent pixels to the reserved transparency index
    mapped_arr[transparent_mask] = trans_index
    result = Image.fromarray(mapped_arr, mode="P")
    result.putpalette(palette_img.getpalette())
    result.info["transparency"] = trans_index
    return result


def save_gif(frames: list[dict], output_path: str, original_path: str):
    """Save frames as an animated GIF preserving timing and transparency."""
    original = Image.open(original_path)
    loop = original.info.get("loop", 0)
    durations = [f["duration"] for f in frames]
    rgba_frames = [f["image"] for f in frames]

    palette, trans_index = build_shared_palette(rgba_frames)

    # Create a palette image to pass to quantize()
    palette_img = Image.new("P", (1, 1))
    palette_img.putpalette(palette)

    palette_frames = [
        rgba_to_gif_frame(f, palette_img, trans_index) for f in rgba_frames
    ]

    palette_frames[0].save(
        output_path,
        save_all=True,
        append_images=palette_frames[1:],
        duration=durations,
        loop=loop,
        disposal=2,
        transparency=trans_index,
    )


def main():
    parser = argparse.ArgumentParser(description="Recolor a red siren GIF")
    parser.add_argument("input", help="Path to the input red siren GIF")
    parser.add_argument(
        "--output-dir",
        default=None,
        help="Output directory (defaults to same as input)",
    )
    parser.add_argument(
        "--colors",
        nargs="+",
        choices=list(COLOR_CONFIGS.keys()),
        default=list(COLOR_CONFIGS.keys()),
        help="Colors to generate (default: all)",
    )
    parser.add_argument(
        "--slow",
        action="store_true",
        help="Use pixel-by-pixel processing (slower but simpler to debug)",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"Error: {input_path} not found")
        return 1

    output_dir = Path(args.output_dir) if args.output_dir else input_path.parent
    output_dir.mkdir(parents=True, exist_ok=True)

    stem = input_path.stem
    recolor_fn = recolor_frame if args.slow else recolor_frame_fast

    print(f"Extracting frames from {input_path}...")
    frames = extract_frames(str(input_path))
    print(f"  Found {len(frames)} frames")

    for color_name in args.colors:
        config = COLOR_CONFIGS[color_name]
        output_path = output_dir / f"{stem}_{color_name}.gif"
        print(f"Generating {color_name} version -> {output_path}")

        recolored_frames = []
        for i, frame in enumerate(frames):
            new_image = recolor_fn(frame["image"], config)
            recolored_frames.append({"image": new_image, "duration": frame["duration"]})
            if (i + 1) % 5 == 0 or i == len(frames) - 1:
                print(f"  Processed frame {i + 1}/{len(frames)}")

        save_gif(recolored_frames, str(output_path), str(input_path))
        print(f"  Saved {output_path}")

    print("Done!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
