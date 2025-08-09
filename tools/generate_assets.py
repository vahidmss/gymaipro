import os
import math
from typing import Tuple

import numpy as np
from PIL import Image, ImageDraw
import imageio


# -----------------------------
# Utilities
# -----------------------------

def ensure_dir(path: str) -> None:
    os.makedirs(path, exist_ok=True)


def hex_to_rgb(hex_color: str) -> Tuple[int, int, int]:
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def lerp(a: np.ndarray, b: np.ndarray, t: np.ndarray) -> np.ndarray:
    return (a * (1.0 - t) + b * t)


def clamp01(x: np.ndarray) -> np.ndarray:
    return np.clip(x, 0.0, 1.0)


def to_uint8(img01: np.ndarray) -> np.ndarray:
    return np.uint8(np.round(clamp01(img01) * 255.0))


# -----------------------------
# Gradient generators
# -----------------------------

def generate_linear_gradient(width: int, height: int, color1: Tuple[int, int, int], color2: Tuple[int, int, int], angle_deg: float) -> Image.Image:
    angle = math.radians(angle_deg)
    x = np.linspace(-0.5, 0.5, width, dtype=np.float32)
    y = np.linspace(-0.5, 0.5, height, dtype=np.float32)
    xv, yv = np.meshgrid(x, y)

    projection = xv * math.cos(angle) + yv * math.sin(angle)

    t = clamp01((projection - projection.min()) / (projection.max() - projection.min()))
    t = np.power(t, 1.1)

    c1 = np.array(color1, dtype=np.float32)[None, None, :] / 255.0
    c2 = np.array(color2, dtype=np.float32)[None, None, :] / 255.0

    img = lerp(c1, c2, t[..., None])
    return Image.fromarray(to_uint8(img), mode='RGB')


def generate_radial_gradient(width: int, height: int, inner: Tuple[int, int, int], outer: Tuple[int, int, int], center_xy: Tuple[float, float]) -> Image.Image:
    cx = (center_xy[0] - 0.5)
    cy = (center_xy[1] - 0.5)

    x = np.linspace(-0.5, 0.5, width, dtype=np.float32)
    y = np.linspace(-0.5, 0.5, height, dtype=np.float32)
    xv, yv = np.meshgrid(x, y)

    dx = xv - cx
    dy = yv - cy
    r = np.sqrt(dx * dx + dy * dy)

    max_r = np.sqrt(0.5 ** 2 + 0.5 ** 2)
    t = clamp01(r / max_r)
    t = np.power(t, 0.9)

    c1 = np.array(inner, dtype=np.float32)[None, None, :] / 255.0
    c2 = np.array(outer, dtype=np.float32)[None, None, :] / 255.0

    img = lerp(c1, c2, t[..., None])
    return Image.fromarray(to_uint8(img), mode='RGB')


def overlay_subtle_grid(img: Image.Image, spacing: int = 64, line_alpha: int = 18) -> Image.Image:
    draw = ImageDraw.Draw(img, 'RGBA')
    width, height = img.size
    line_color = (255, 255, 255, line_alpha)

    for x in range(0, width, spacing):
        draw.line([(x, 0), (x, height)], fill=line_color, width=1)
    for y in range(0, height, spacing):
        draw.line([(0, y), (width, y)], fill=line_color, width=1)

    return img


def overlay_subtle_noise(img: Image.Image, strength: float = 0.02, seed: int = 42) -> Image.Image:
    np.random.seed(seed)
    arr = np.asarray(img).astype(np.float32) / 255.0
    noise = np.random.normal(loc=0.0, scale=strength, size=arr.shape).astype(np.float32)
    arr_noisy = clamp01(arr + noise)
    return Image.fromarray(to_uint8(arr_noisy), mode='RGB')


# -----------------------------
# Image set generation
# -----------------------------

def generate_image_set(output_dir: str) -> None:
    ensure_dir(output_dir)

    palette_hex = [
        '#0ea5e9', '#22d3ee', '#6366f1', '#8b5cf6', '#1e3a8a', '#4f46e5', '#06b6d4', '#7c3aed'
    ]
    palette = [hex_to_rgb(h) for h in palette_hex]

    specs = [
        (1280, 720, '16x9'),
        (720, 1280, '9x16'),
    ]

    num_per_ratio = 10

    for width, height, tag in specs:
        for idx in range(num_per_ratio):
            c1 = palette[(idx * 2) % len(palette)]
            c2 = palette[(idx * 2 + 3) % len(palette)]

            if idx % 2 == 0:
                angle = (idx * 23) % 180
                base = generate_linear_gradient(width, height, c1, c2, angle)
            else:
                cx = 0.5 + 0.2 * math.cos(idx)
                cy = 0.5 + 0.2 * math.sin(idx * 1.3)
                base = generate_radial_gradient(width, height, c1, c2, (cx, cy))

            with_grid = overlay_subtle_grid(base, spacing=64 if width >= 1000 else 48, line_alpha=16)
            final_img = overlay_subtle_noise(with_grid, strength=0.015, seed=idx * 13 + (0 if tag == '16x9' else 7))

            filename = f"img_{idx+1:02d}_{tag}.png"
            final_img.save(os.path.join(output_dir, filename), format='PNG', optimize=True)


# -----------------------------
# Video generation using imageio-ffmpeg
# -----------------------------

def make_linear_gradient_frame(width: int, height: int, color1: Tuple[int, int, int], color2: Tuple[int, int, int], angle_deg: float) -> np.ndarray:
    angle = math.radians(angle_deg)
    x = np.linspace(-0.5, 0.5, width, dtype=np.float32)
    y = np.linspace(-0.5, 0.5, height, dtype=np.float32)
    xv, yv = np.meshgrid(x, y)
    projection = xv * math.cos(angle) + yv * math.sin(angle)
    t = clamp01((projection - projection.min()) / (projection.max() - projection.min()))
    t = np.power(t, 1.1)
    c1 = np.array(color1, dtype=np.float32)[None, None, :] / 255.0
    c2 = np.array(color2, dtype=np.float32)[None, None, :] / 255.0
    img = lerp(c1, c2, t[..., None])

    spacing = 48 if width < 1000 else 64
    grid_x = ((np.arange(width)[None, :] % spacing) == 0)
    grid_y = ((np.arange(height)[:, None] % spacing) == 0)
    grid_mask = np.logical_or(grid_x, grid_y)[..., None]
    grid_overlay = np.where(grid_mask, 1.0, 0.0).astype(np.float32) * (16.0 / 255.0)
    img = clamp01(img + grid_overlay)

    return to_uint8(img)


def make_radial_gradient_frame(width: int, height: int, inner: Tuple[int, int, int], outer: Tuple[int, int, int], center_xy: Tuple[float, float]) -> np.ndarray:
    cx = (center_xy[0] - 0.5)
    cy = (center_xy[1] - 0.5)
    x = np.linspace(-0.5, 0.5, width, dtype=np.float32)
    y = np.linspace(-0.5, 0.5, height, dtype=np.float32)
    xv, yv = np.meshgrid(x, y)
    dx = xv - cx
    dy = yv - cy
    r = np.sqrt(dx * dx + dy * dy)
    max_r = np.sqrt(0.5 ** 2 + 0.5 ** 2)
    t = clamp01(r / max_r)
    t = np.power(t, 0.9)
    c1 = np.array(inner, dtype=np.float32)[None, None, :] / 255.0
    c2 = np.array(outer, dtype=np.float32)[None, None, :] / 255.0
    img = lerp(c1, c2, t[..., None])

    spacing = 48 if width < 1000 else 64
    grid_x = ((np.arange(width)[None, :] % spacing) == 0)
    grid_y = ((np.arange(height)[:, None] % spacing) == 0)
    grid_mask = np.logical_or(grid_x, grid_y)[..., None]
    grid_overlay = np.where(grid_mask, 1.0, 0.0).astype(np.float32) * (16.0 / 255.0)
    img = clamp01(img + grid_overlay)

    return to_uint8(img)


def generate_videos(output_dir: str) -> None:
    ensure_dir(output_dir)

    palette_hex = ['#0ea5e9', '#22d3ee', '#6366f1', '#8b5cf6', '#1e3a8a', '#4f46e5', '#06b6d4', '#7c3aed']
    palette = [hex_to_rgb(h) for h in palette_hex]

    specs = [
        (1280, 720, '16x9'),
        (720, 1280, '9x16'),
    ]

    duration = 4.0
    fps = 24
    num_frames = int(duration * fps)

    idx_global = 0
    for width, height, tag in specs:
        for k in range(3):
            c1 = palette[(idx_global * 2) % len(palette)]
            c2 = palette[(idx_global * 2 + 3) % len(palette)]

            filename = os.path.join(output_dir, f"vid_{k+1}_{tag}.mp4")
            writer = imageio.get_writer(
                filename,
                fps=fps,
                codec='libx264',
                quality=None,
                bitrate='4000k',
                macro_block_size=None,
                ffmpeg_log_level='error',
                pixelformat='yuv420p',
            )

            try:
                for frame_index in range(num_frames):
                    t = frame_index / fps
                    if k % 2 == 0:
                        angle = (t / duration) * 180.0 + (idx_global * 13 % 90)
                        frame = make_linear_gradient_frame(width, height, c1, c2, angle)
                    else:
                        cx = 0.5 + 0.25 * math.sin(2 * math.pi * (t / duration))
                        cy = 0.5 + 0.20 * math.sin(2 * math.pi * (t / duration) * 0.7 + 1.3)
                        frame = make_radial_gradient_frame(width, height, c1, c2, (cx, cy))

                    writer.append_data(frame)
            finally:
                writer.close()

            idx_global += 1


# -----------------------------
# Zip helper
# -----------------------------

def zip_folder(folder_path: str, zip_path: str) -> None:
    import zipfile
    with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        for root, _dirs, files in os.walk(folder_path):
            for name in files:
                file_path = os.path.join(root, name)
                arcname = os.path.relpath(file_path, folder_path)
                zf.write(file_path, arcname)


# -----------------------------
# Main
# -----------------------------

def main() -> None:
    base_out = os.path.join('/workspace', 'assets')
    images_out = os.path.join(base_out, 'images')
    videos_out = os.path.join(base_out, 'videos')

    print('Generating images...')
    generate_image_set(images_out)
    print('Generating videos...')
    generate_videos(videos_out)

    zip_path = os.path.join('/workspace', 'assets_minimal_pack.zip')
    print('Zipping output to', zip_path)
    zip_folder(base_out, zip_path)

    print('Done. Output folder:', base_out)
    print('Zip file:', zip_path)


if __name__ == '__main__':
    main()