#!/usr/bin/env python3
"""Generate deterministic MVP art assets without third-party dependencies.

The source art plan asks for image_gen-backed production art. This script is a
local fallback that creates valid, stylized, transparent PNG assets at the same
runtime paths so the MVP can load, reference, and QA the resource contract.
"""

from __future__ import annotations

import argparse
import json
import math
import random
import struct
import zlib
from pathlib import Path
from typing import Callable


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"

PALETTE = {
    "panel_bg_primary": (0x1A, 0x1A, 0x20, 255),
    "panel_bg_secondary": (0x24, 0x24, 0x30, 255),
    "panel_bg_elevated": (0x2E, 0x2E, 0x3C, 255),
    "text_primary": (0xE8, 0xE0, 0xD0, 255),
    "text_secondary": (0x9A, 0x94, 0x88, 255),
    "ink": (0x3D, 0x38, 0x30, 255),
    "warm_paper": (0xF5, 0xED, 0xDB, 255),
    "gold": (0xF5, 0xC8, 0x42, 255),
    "orange": (0xD4, 0x76, 0x2A, 255),
    "red": (0xB0, 0x40, 0x40, 255),
    "failure_red": (0xCC, 0x22, 0x22, 255),
    "purple": (0x5B, 0x3D, 0x82, 255),
    "blue": (0x3A, 0x7F, 0xCC, 255),
    "teal": (0x5F, 0xCF, 0xD5, 255),
    "jade": (0x4F, 0xA6, 0x7A, 255),
    "herb": (0x7B, 0xAA, 0x48, 255),
    "indigo": (0x5B, 0x5D, 0xA8, 255),
    "common": (0x70, 0x70, 0x70, 255),
    "uncommon": (0xC8, 0xC8, 0xC0, 255),
    "rare": (0x3A, 0x7F, 0xCC, 255),
    "epic": (0x88, 0x44, 0xCC, 255),
    "legendary": (0xD4, 0xA8, 0x20, 255),
    "mythic": (0xFF, 0x9A, 0x00, 255),
    "innate": (0xA8, 0xE8, 0xD8, 255),
    "chaos_a": (0xCC, 0x22, 0x88, 255),
    "chaos_b": (0x44, 0x88, 0xFF, 255),
}


class Canvas:
    def __init__(self, width: int, height: int, color=(0, 0, 0, 0)) -> None:
        self.width = width
        self.height = height
        self.data = bytearray(width * height * 4)
        if color[3] > 0:
            self.fill(color)

    def fill(self, color) -> None:
        r, g, b, a = color
        px = bytes((r, g, b, a))
        self.data[:] = px * (self.width * self.height)

    def blend_pixel(self, x: int, y: int, color) -> None:
        if x < 0 or y < 0 or x >= self.width or y >= self.height:
            return
        sr, sg, sb, sa = color
        if sa <= 0:
            return
        idx = (y * self.width + x) * 4
        dr, dg, db, da = self.data[idx], self.data[idx + 1], self.data[idx + 2], self.data[idx + 3]
        if sa == 255 or da == 0:
            self.data[idx : idx + 4] = bytes((sr, sg, sb, sa))
            return
        out_a = sa + da * (255 - sa) // 255
        if out_a <= 0:
            return
        out_r = (sr * sa + dr * da * (255 - sa) // 255) // out_a
        out_g = (sg * sa + dg * da * (255 - sa) // 255) // out_a
        out_b = (sb * sa + db * da * (255 - sa) // 255) // out_a
        self.data[idx : idx + 4] = bytes((clamp_byte(out_r), clamp_byte(out_g), clamp_byte(out_b), clamp_byte(out_a)))

    def rect(self, x: int, y: int, w: int, h: int, color) -> None:
        x0 = max(0, x)
        y0 = max(0, y)
        x1 = min(self.width, x + w)
        y1 = min(self.height, y + h)
        for yy in range(y0, y1):
            for xx in range(x0, x1):
                self.blend_pixel(xx, yy, color)

    def rect_outline(self, x: int, y: int, w: int, h: int, color, thickness: int = 1) -> None:
        self.rect(x, y, w, thickness, color)
        self.rect(x, y + h - thickness, w, thickness, color)
        self.rect(x, y, thickness, h, color)
        self.rect(x + w - thickness, y, thickness, h, color)

    def ellipse(self, cx: int, cy: int, rx: int, ry: int, color) -> None:
        if rx <= 0 or ry <= 0:
            return
        for yy in range(cy - ry, cy + ry + 1):
            dy = (yy - cy) / float(ry)
            if abs(dy) > 1:
                continue
            span = int(rx * math.sqrt(max(0.0, 1.0 - dy * dy)))
            for xx in range(cx - span, cx + span + 1):
                self.blend_pixel(xx, yy, color)

    def ellipse_outline(self, cx: int, cy: int, rx: int, ry: int, color, thickness: int = 2) -> None:
        for t in range(thickness):
            outer_rx = max(1, rx - t)
            outer_ry = max(1, ry - t)
            inner_rx = max(0, rx - thickness - t)
            inner_ry = max(0, ry - thickness - t)
            for yy in range(cy - outer_ry, cy + outer_ry + 1):
                dy = (yy - cy) / float(outer_ry)
                if abs(dy) > 1:
                    continue
                span = int(outer_rx * math.sqrt(max(0.0, 1.0 - dy * dy)))
                inner_span = -1
                if inner_rx > 0 and inner_ry > 0:
                    idy = (yy - cy) / float(inner_ry)
                    if abs(idy) <= 1:
                        inner_span = int(inner_rx * math.sqrt(max(0.0, 1.0 - idy * idy)))
                for xx in range(cx - span, cx + span + 1):
                    if inner_span >= 0 and cx - inner_span <= xx <= cx + inner_span:
                        continue
                    self.blend_pixel(xx, yy, color)

    def line(self, x0: int, y0: int, x1: int, y1: int, color, thickness: int = 1) -> None:
        dx = x1 - x0
        dy = y1 - y0
        steps = max(abs(dx), abs(dy), 1)
        radius = max(0, thickness // 2)
        for i in range(steps + 1):
            x = int(round(x0 + dx * i / steps))
            y = int(round(y0 + dy * i / steps))
            if radius <= 0:
                self.blend_pixel(x, y, color)
            else:
                self.ellipse(x, y, radius, radius, color)

    def polygon(self, points: list[tuple[int, int]], color) -> None:
        if len(points) < 3:
            return
        ys = [p[1] for p in points]
        for y in range(max(0, min(ys)), min(self.height, max(ys) + 1)):
            intersections = []
            for i, p1 in enumerate(points):
                p2 = points[(i + 1) % len(points)]
                x1, y1 = p1
                x2, y2 = p2
                if y1 == y2:
                    continue
                if (y >= min(y1, y2)) and (y < max(y1, y2)):
                    x = x1 + (y - y1) * (x2 - x1) / float(y2 - y1)
                    intersections.append(int(round(x)))
            intersections.sort()
            for i in range(0, len(intersections), 2):
                if i + 1 >= len(intersections):
                    break
                self.rect(intersections[i], y, intersections[i + 1] - intersections[i] + 1, 1, color)

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        raw = bytearray()
        stride = self.width * 4
        for y in range(self.height):
            raw.append(0)
            start = y * stride
            raw.extend(self.data[start : start + stride])
        compressed = zlib.compress(bytes(raw), level=9)
        with path.open("wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n")
            self._chunk(f, b"IHDR", struct.pack(">IIBBBBB", self.width, self.height, 8, 6, 0, 0, 0))
            self._chunk(f, b"IDAT", compressed)
            self._chunk(f, b"IEND", b"")

    @staticmethod
    def _chunk(f, chunk_type: bytes, data: bytes) -> None:
        f.write(struct.pack(">I", len(data)))
        f.write(chunk_type)
        f.write(data)
        f.write(struct.pack(">I", zlib.crc32(chunk_type + data) & 0xFFFFFFFF))


def rgba(color, alpha: int | None = None):
    r, g, b, a = color
    return (r, g, b, a if alpha is None else alpha)


def clamp_byte(value: int) -> int:
    return max(0, min(255, int(value)))


def write_sidecars(path: Path, prompt: str, meta: dict) -> None:
    prompt_path = path.with_suffix(".prompt.txt")
    meta_path = path.with_suffix(".pipeline-meta.json")
    prompt_path.write_text(prompt + "\n", encoding="utf-8")
    meta_path.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def emit(path: str, width: int, height: int, draw: Callable[[Canvas], None], prompt: str, category: str, log: list[dict]) -> None:
    out = ROOT / path
    canvas = Canvas(width, height)
    draw(canvas)
    canvas.save(out)
    meta = {
        "asset_path": path,
        "width": width,
        "height": height,
        "category": category,
        "source": "deterministic_mvp_fallback",
        "style_lock": "clean_hd chinese ink-inspired minimal vector raster",
        "alpha": has_alpha(canvas),
        "generator": "scripts/generate_mvp_assets.py",
    }
    write_sidecars(out, prompt, meta)
    log.append({"path": path, "status": "generated", "width": width, "height": height, "category": category, "source": meta["source"]})


def has_alpha(canvas: Canvas) -> bool:
    return any(canvas.data[i + 3] < 255 for i in range(0, len(canvas.data), 4))


def seed_for(name: str) -> random.Random:
    seed = int.from_bytes(name.encode("utf-8"), "little", signed=False) % (2**32)
    return random.Random(seed)


def draw_brush_noise(c: Canvas, seed: str, color, count: int, max_radius: int) -> None:
    rnd = seed_for(seed)
    for _ in range(count):
        x = rnd.randrange(0, c.width)
        y = rnd.randrange(0, c.height)
        rx = rnd.randrange(2, max_radius)
        ry = rnd.randrange(2, max_radius)
        c.ellipse(x, y, rx, ry, rgba(color, rnd.randrange(12, 45)))


def draw_swirl(c: Canvas, cx: int, cy: int, radius: int, color, turns: float = 1.4) -> None:
    points = []
    for i in range(90):
        t = i / 89.0
        angle = t * math.tau * turns
        r = radius * t
        points.append((int(cx + math.cos(angle) * r), int(cy + math.sin(angle) * r)))
    for a, b in zip(points, points[1:]):
        c.line(a[0], a[1], b[0], b[1], rgba(color, 210), 3)


def draw_icon_base(c: Canvas, color, accent=None) -> None:
    c.ellipse(32, 32, 25, 25, rgba(PALETTE["ink"], 110))
    c.ellipse_outline(32, 32, 25, 25, rgba(color, 210), 3)
    if accent:
        c.ellipse(32, 32, 6, 6, rgba(accent, 220))


def draw_resource_icon(kind: str, color) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        draw_icon_base(c, color, PALETTE["text_primary"])
        if kind == "lingqi":
            draw_swirl(c, 32, 32, 22, color)
        elif kind == "xiuwei":
            c.ellipse(32, 34, 14, 8, rgba(color, 220))
            c.ellipse_outline(32, 28, 18, 18, rgba(PALETTE["ink"], 170), 2)
        elif kind == "lingshi":
            c.polygon([(32, 9), (50, 25), (45, 49), (19, 51), (12, 24)], rgba(color, 230))
            c.line(32, 9, 32, 51, rgba(PALETTE["ink"], 180), 2)
            c.line(12, 24, 50, 25, rgba(PALETTE["ink"], 150), 2)
        elif kind == "herb":
            c.line(32, 49, 32, 15, rgba(PALETTE["ink"], 200), 3)
            c.ellipse(24, 28, 9, 15, rgba(color, 230))
            c.ellipse(40, 24, 9, 15, rgba(color, 230))
            c.ellipse(33, 15, 6, 10, rgba(PALETTE["red"], 210))
        elif kind == "exp":
            c.polygon([(17, 40), (30, 18), (47, 15), (35, 37), (49, 46), (26, 45)], rgba(color, 230))
            c.line(19, 43, 46, 17, rgba(PALETTE["text_primary"], 150), 2)

    return draw


def draw_stance_icon(kind: str) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        draw_icon_base(c, PALETTE["text_secondary"])
        if kind == "closed_door":
            c.rect(20, 14, 25, 37, rgba(PALETTE["ink"], 220))
            c.rect_outline(20, 14, 25, 37, rgba(PALETTE["warm_paper"], 150), 2)
            c.line(32, 16, 32, 50, rgba(PALETTE["purple"], 180), 2)
        else:
            body = PALETTE["teal"] if kind == "meditate" else PALETTE["indigo"] if kind == "condense" else PALETTE["text_secondary"]
            c.ellipse(32, 21, 7, 8, rgba(body, 230))
            c.rect(28, 29, 8, 15, rgba(PALETTE["ink"], 210))
            c.ellipse(22, 43, 13, 5, rgba(body, 220))
            c.ellipse(42, 43, 13, 5, rgba(body, 220))
            if kind == "condense":
                draw_swirl(c, 32, 34, 15, PALETTE["indigo"], 1.0)
            if kind == "meditate":
                c.line(32, 13, 37, 5, rgba(PALETTE["teal"], 180), 2)

    return draw


def draw_status_icon(kind: str) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        cx = cy = 24
        if kind == "overflow_warn":
            c.polygon([(24, 5), (43, 40), (5, 40)], rgba(PALETTE["red"], 230))
            c.rect(23, 16, 3, 14, rgba(PALETTE["warm_paper"], 230))
            c.rect(23, 33, 3, 3, rgba(PALETTE["warm_paper"], 230))
        elif kind == "combat_active":
            c.line(12, 38, 37, 13, rgba(PALETTE["orange"], 230), 5)
            c.line(33, 11, 39, 17, rgba(PALETTE["text_primary"], 210), 3)
            c.rect_outline(7, 7, 34, 34, rgba(PALETTE["orange"], 150), 2)
        elif kind == "combat_failed":
            c.ellipse(cx, cy, 18, 18, rgba(PALETTE["failure_red"], 210))
            c.line(15, 15, 33, 33, rgba(PALETTE["warm_paper"], 230), 4)
            c.line(33, 15, 15, 33, rgba(PALETTE["warm_paper"], 230), 4)
        elif kind == "level_up":
            c.polygon([(24, 4), (29, 18), (44, 18), (32, 27), (37, 42), (24, 32), (11, 42), (16, 27), (4, 18), (19, 18)], rgba(PALETTE["gold"], 235))
        elif kind == "offline_pending":
            c.rect(10, 12, 28, 26, rgba(PALETTE["warm_paper"], 235))
            c.rect_outline(10, 12, 28, 26, rgba(PALETTE["ink"], 170), 2)
            c.ellipse(32, 17, 5, 5, rgba(PALETTE["gold"], 230))

    return draw


def draw_frame_asset(color, glow: int = 0, chaos: bool = False) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        x, y, w, h = 16, 16, 96, 96
        if glow > 0:
            for i in range(glow, 0, -3):
                alpha = max(15, 55 - i)
                c.rect_outline(x - i, y - i, w + 2 * i, h + 2 * i, rgba(color, alpha), 2)
        if chaos:
            c.rect_outline(x, y, w, h, rgba(PALETTE["chaos_a"], 235), 4)
            c.line(x, y, x + w, y + h, rgba(PALETTE["chaos_b"], 180), 2)
            c.line(x + w, y, x, y + h, rgba(PALETTE["gold"], 180), 2)
            return
        c.rect_outline(x, y, w, h, rgba(color, 245), max(1, min(4, glow // 4 + 1)))
        c.line(x + w - 18, y, x + w, y + 18, rgba(color, 245), max(1, min(4, glow // 4 + 1)))

    return draw


def draw_realm_badge(kind: str, color) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        c.ellipse(48, 48, 36, 36, rgba(PALETTE["ink"], 120))
        c.ellipse_outline(48, 48, 36, 36, rgba(color, 220), 4)
        c.ellipse(48, 35, 9, 10, rgba(PALETTE["text_primary"], 220))
        c.rect(42, 46, 13, 20, rgba(PALETTE["panel_bg_secondary"], 240))
        if kind != "mortal":
            draw_swirl(c, 48, 50, 26, color, 1.0)
        if kind in {"foundation", "golden_core", "yuanying", "huashen", "heti"}:
            c.ellipse(48, 68, 20, 6, rgba(color, 160))
        if kind in {"golden_core", "yuanying", "huashen", "heti"}:
            c.ellipse(48, 52, 7, 7, rgba(PALETTE["gold"], 235))
        if kind in {"yuanying", "huashen", "heti"}:
            c.ellipse_outline(48, 48, 42, 42, rgba(PALETTE["innate"], 100), 2)

    return draw


def draw_panel(color, elevated: bool = False, chamfer: bool = True) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        if chamfer:
            c.polygon([(0, 0), (184, 0), (191, 7), (191, 191), (0, 191)], color)
        else:
            c.rect(0, 0, 192, 192, color)
        c.rect_outline(6, 6, 180, 180, rgba(PALETTE["ink"], 190), 2)
        if elevated:
            c.line(10, 8, 180, 8, rgba(PALETTE["text_primary"], 140), 2)

    return draw


def draw_button_states(c: Canvas) -> None:
    states = [PALETTE["panel_bg_secondary"], PALETTE["ink"], PALETTE["panel_bg_primary"]]
    for row, color in enumerate(states):
        y = row * 96
        c.rect(0, y, 96, 96, color)
        c.rect_outline(5, y + 5, 86, 86, rgba(PALETTE["text_secondary"], 160), 2)
        c.line(24, y + 48, 72, y + 48, rgba(PALETTE["gold"], 180), 3)


def draw_seal(color, variant: str) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        cx = cy = 256
        pts = []
        for i in range(8):
            angle = math.tau * i / 8 + math.pi / 8
            radius = 205 if i % 2 == 0 else 180
            pts.append((int(cx + math.cos(angle) * radius), int(cy + math.sin(angle) * radius)))
        c.polygon(pts, rgba(color, 180))
        c.ellipse_outline(cx, cy, 172, 172, rgba(PALETTE["ink"], 210), 10)
        if variant == "ink":
            draw_swirl(c, cx, cy, 140, PALETTE["ink"], 2.0)
        else:
            c.line(180, 205, 332, 205, rgba(PALETTE["warm_paper"], 230), 18)
            c.line(256, 150, 256, 355, rgba(PALETTE["warm_paper"], 230), 18)
            c.line(205, 295, 315, 185, rgba(PALETTE["warm_paper"], 210), 14)
        draw_brush_noise(c, "seal-" + variant, color, 120, 12)

    return draw


def draw_actor(c: Canvas, x: int, y: int, scale: float, color, frame: int = 0, kind: str = "player") -> None:
    bob = int(math.sin(frame * math.pi / 2) * 4 * scale)
    ink = PALETTE["ink"]
    if kind == "player":
        c.ellipse(x, y - int(48 * scale) + bob, int(11 * scale), int(13 * scale), rgba(PALETTE["text_primary"], 230))
        c.polygon([(x, y - int(35 * scale) + bob), (x - int(28 * scale), y + int(45 * scale)), (x + int(28 * scale), y + int(45 * scale))], rgba(PALETTE["panel_bg_secondary"], 240))
        c.line(x - int(25 * scale), y - int(8 * scale), x - int(45 * scale), y + int(35 * scale), rgba(color, 230), int(5 * scale))
        c.line(x + int(25 * scale), y - int(8 * scale), x + int(45 * scale), y + int(35 * scale), rgba(color, 230), int(5 * scale))
        c.line(x + int(18 * scale), y - int(14 * scale), x + int(52 * scale), y + int(26 * scale), rgba(PALETTE["gold"], 230), int(3 * scale))
    elif kind in {"wolf", "rat", "shark"}:
        c.ellipse(x, y, int(38 * scale), int(18 * scale), rgba(color, 235))
        c.ellipse(x + int(30 * scale), y - int(8 * scale), int(16 * scale), int(13 * scale), rgba(color, 235))
        c.polygon([(x + int(27 * scale), y - int(21 * scale)), (x + int(34 * scale), y - int(37 * scale)), (x + int(41 * scale), y - int(21 * scale))], rgba(ink, 210))
        c.line(x - int(35 * scale), y, x - int(55 * scale), y + int(12 * scale), rgba(color, 200), int(5 * scale))
    elif kind in {"ghost", "smoke", "dragon"}:
        c.ellipse(x, y, int(36 * scale), int(48 * scale), rgba(color, 160))
        draw_swirl(c, x, y, int(40 * scale), color, 1.2)
        c.ellipse(x - int(10 * scale), y - int(12 * scale), int(4 * scale), int(4 * scale), rgba(PALETTE["failure_red"], 230))
        c.ellipse(x + int(10 * scale), y - int(12 * scale), int(4 * scale), int(4 * scale), rgba(PALETTE["failure_red"], 230))
    else:
        c.ellipse(x, y - int(44 * scale), int(10 * scale), int(13 * scale), rgba(PALETTE["text_primary"], 220))
        c.polygon([(x, y - int(30 * scale)), (x - int(23 * scale), y + int(40 * scale)), (x + int(23 * scale), y + int(40 * scale))], rgba(color, 235))
        c.line(x + int(12 * scale), y - int(8 * scale), x + int(48 * scale), y + int(25 * scale), rgba(PALETTE["failure_red"], 210), int(4 * scale))


def draw_sheet(rows: int, cols: int, kind: str, color, action: str = "idle") -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        cell_w = c.width // cols
        cell_h = c.height // rows
        for row in range(rows):
            for col in range(cols):
                frame = row * cols + col
                cx = col * cell_w + cell_w // 2
                cy = row * cell_h + int(cell_h * 0.62)
                if action in {"attack", "projectile"}:
                    cx += int((col - (cols - 1) / 2.0) * 9)
                if action == "death":
                    cy += int(frame * 5)
                draw_actor(c, cx, cy, min(cell_w, cell_h) / 180.0, color, frame, kind)
                if action == "attack":
                    c.line(cx + 18, cy - 25, cx + 65, cy - 40 + frame % 3 * 8, rgba(PALETTE["gold"], 170), 5)
                if action == "projectile":
                    c.ellipse(cx + 45, cy - 30, 16, 16, rgba(color, 190))

    return draw


def draw_portrait(kind: str, color) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        scale = min(c.width, c.height) / 300.0
        draw_actor(c, c.width // 2, int(c.height * 0.64), scale, color, 0, kind)
        c.ellipse_outline(c.width // 2, int(c.height * 0.52), int(c.width * 0.33), int(c.height * 0.27), rgba(color, 80), 5)

    return draw


def draw_map(name: str, base, accent) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        for y in range(c.height):
            t = y / max(1, c.height - 1)
            r = int(base[0] * (1 - t) + accent[0] * t)
            g = int(base[1] * (1 - t) + accent[1] * t)
            b = int(base[2] * (1 - t) + accent[2] * t)
            c.rect(0, y, c.width, 1, (r, g, b, 255))
        rnd = seed_for(name)
        for layer in range(4):
            y_base = int(c.height * (0.35 + layer * 0.12))
            color = rgba(PALETTE["ink"], 70 + layer * 25)
            last = (0, y_base + rnd.randrange(-40, 40))
            for x in range(0, c.width + 120, 120):
                point = (x, y_base + rnd.randrange(-70, 70))
                c.line(last[0], last[1], point[0], point[1], color, 10 + layer * 5)
                last = point
        if name == "main_base":
            c.rect(c.width // 2 - 120, int(c.height * 0.63), 240, 80, rgba(PALETTE["ink"], 200))
            c.ellipse(c.width // 2, int(c.height * 0.61), 170, 90, rgba(PALETTE["panel_bg_primary"], 230))
        elif name == "town_economy":
            for i in range(18):
                x = 200 + (i % 6) * 250
                y = 260 + (i // 6) * 190
                c.polygon([(x, y), (x + 80, y - 45), (x + 160, y), (x + 140, y + 70), (x + 20, y + 70)], rgba(PALETTE["panel_bg_secondary"], 210))
                c.rect_outline(x + 20, y, 120, 70, rgba(PALETTE["ink"], 180), 3)
        else:
            for i in range(28):
                x = rnd.randrange(80, c.width - 80)
                y = rnd.randrange(int(c.height * 0.42), c.height - 90)
                c.line(x, y, x + rnd.randrange(-20, 20), y - rnd.randrange(60, 150), rgba(PALETTE["ink"], rnd.randrange(90, 180)), rnd.randrange(4, 9))
        draw_brush_noise(c, name, PALETTE["ink"], 180, 20)

    return draw


def draw_failure_overlay(c: Canvas) -> None:
    cx, cy = c.width // 2, c.height // 2
    max_d = math.hypot(cx, cy)
    for y in range(c.height):
        for x in range(c.width):
            d = math.hypot(x - cx, y - cy) / max_d
            alpha = int(95 + d * 85)
            c.blend_pixel(x, y, (0x1A, 0x1A, 0x20, alpha))
    draw_brush_noise(c, "failure", PALETTE["ink"], 220, 24)


def draw_offline_paper(c: Canvas) -> None:
    c.rect(0, 0, c.width, c.height, (0, 0, 0, 0))
    margin_x = int(c.width * 0.08)
    margin_y = int(c.height * 0.08)
    c.rect(margin_x, margin_y, c.width - 2 * margin_x, c.height - 2 * margin_y, rgba(PALETTE["warm_paper"], 242))
    c.rect_outline(margin_x, margin_y, c.width - 2 * margin_x, c.height - 2 * margin_y, rgba(PALETTE["ink"], 90), 4)
    draw_brush_noise(c, "offline-paper", PALETTE["gold"], 90, 10)


def draw_item_icon(kind: str, color) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        draw_resource_icon("lingshi" if "lingshi" in kind or "crystal" in kind or "scale" in kind or "ore" in kind else "herb" if "grass" in kind or "ginseng" in kind else "exp", color)(c)

    return draw


def draw_prop_pack(items: list[tuple[str, tuple[int, int, int, int]]], cols: int, rows: int) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        cell_w = c.width // cols
        cell_h = c.height // rows
        for index, (name, color) in enumerate(items):
            col = index % cols
            row = index // cols
            sub = Canvas(64, 64)
            draw_item_icon(name, color)(sub)
            paste(c, sub, col * cell_w + cell_w // 2 - 32, row * cell_h + cell_h // 2 - 32)

    return draw


def paste(dst: Canvas, src: Canvas, x0: int, y0: int) -> None:
    for y in range(src.height):
        for x in range(src.width):
            idx = (y * src.width + x) * 4
            dst.blend_pixel(x0 + x, y0 + y, tuple(src.data[idx : idx + 4]))


def draw_vfx_sheet(kind: str, rows: int, cols: int, color, cell_w: int, cell_h: int) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        for row in range(rows):
            for col in range(cols):
                frame = row * cols + col
                cx = col * cell_w + cell_w // 2
                cy = row * cell_h + cell_h // 2
                t = (frame + 1) / float(rows * cols)
                if kind == "ring":
                    c.ellipse_outline(cx, cy, int(cell_w * 0.12 + cell_w * 0.32 * t), int(cell_h * 0.12 + cell_h * 0.32 * t), rgba(color, int(240 * (1 - t * 0.45))), 4)
                elif kind == "burst":
                    for i in range(18):
                        ang = math.tau * i / 18
                        r1 = int(18 * t)
                        r2 = int(min(cell_w, cell_h) * 0.42 * t)
                        c.line(cx + int(math.cos(ang) * r1), cy + int(math.sin(ang) * r1), cx + int(math.cos(ang) * r2), cy + int(math.sin(ang) * r2), rgba(color, 210), 5)
                elif kind == "spark":
                    for i in range(8):
                        ang = math.tau * i / 8
                        c.line(cx, cy, cx + int(math.cos(ang) * cell_w * 0.35 * t), cy + int(math.sin(ang) * cell_h * 0.35 * t), rgba(color, 220), 4)
                elif kind == "warn":
                    c.ellipse(cx, cy, int(cell_w * 0.2 + 10 * t), int(cell_h * 0.2 + 10 * t), rgba(color, int(180 * (1 - t * 0.35))))

    return draw


def draw_wipe_frame(amount: float) -> Callable[[Canvas], None]:
    def draw(c: Canvas) -> None:
        cover = int(c.width * amount)
        c.rect(0, 0, cover, c.height, rgba(PALETTE["panel_bg_primary"], 255))
        rnd = seed_for("wipe-%s" % amount)
        for y in range(0, c.height, 12):
            edge = cover + rnd.randrange(-45, 45)
            c.line(edge, y, edge + rnd.randrange(-40, 40), min(c.height - 1, y + 24), rgba(PALETTE["ink"], 210), 10)

    return draw


def validate_png(path: Path) -> tuple[int, int, int, bool]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        raise ValueError(f"not a PNG: {path}")
    pos = 8
    width = height = color_type = None
    idat = bytearray()
    while pos < len(data):
        length = struct.unpack(">I", data[pos : pos + 4])[0]
        chunk_type = data[pos + 4 : pos + 8]
        chunk = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if chunk_type == b"IHDR":
            width, height, _bit_depth, color_type, _comp, _filter, _interlace = struct.unpack(">IIBBBBB", chunk)
        elif chunk_type == b"IDAT":
            idat.extend(chunk)
        elif chunk_type == b"IEND":
            break
    if width is None or height is None or color_type != 6:
        raise ValueError(f"unsupported PNG header: {path}")
    raw = zlib.decompress(bytes(idat))
    stride = width * 4
    alpha = False
    offset = 0
    for _ in range(height):
        filter_type = raw[offset]
        if filter_type != 0:
            raise ValueError(f"unsupported filter {filter_type}: {path}")
        row = raw[offset + 1 : offset + 1 + stride]
        alpha = alpha or any(row[i] < 255 for i in range(3, len(row), 4))
        offset += 1 + stride
    return width, height, color_type, alpha


def build_assets() -> list[dict]:
    log: list[dict] = []
    style = "Chinese xianxia ink-inspired clean HD MVP fallback."

    resources = [
        ("lingqi", PALETTE["teal"]),
        ("xiuwei", PALETTE["indigo"]),
        ("lingshi", PALETTE["jade"]),
        ("herb", PALETTE["herb"]),
        ("exp", (0xD4, 0x9C, 0x3A, 255)),
    ]
    for name, color in resources:
        emit(f"assets/ui/icons/resources/{name}.png", 64, 64, draw_resource_icon(name, color), f"{style} Resource icon {name}.", "ui_resource_icon", log)

    for name in ["idle", "meditate", "condense", "closed_door"]:
        emit(f"assets/ui/icons/stances/{name}.png", 64, 64, draw_stance_icon(name), f"{style} Cultivation stance icon {name}.", "ui_stance_icon", log)

    for name in ["overflow_warn", "combat_active", "combat_failed", "level_up", "offline_pending"]:
        emit(f"assets/ui/icons/status/{name}.png", 48, 48, draw_status_icon(name), f"{style} Status icon {name}.", "ui_status_icon", log)

    rarity = [
        ("common", PALETTE["common"], 0, False),
        ("uncommon", PALETTE["uncommon"], 0, False),
        ("rare", PALETTE["rare"], 4, False),
        ("epic", PALETTE["epic"], 6, False),
        ("legendary", PALETTE["legendary"], 8, False),
        ("mythic", PALETTE["mythic"], 12, False),
        ("innate", PALETTE["innate"], 16, False),
        ("chaos", PALETTE["chaos_a"], 24, True),
    ]
    for name, color, glow, chaos in rarity:
        emit(f"assets/ui/icons/rarity/{name}_frame.png", 128, 128, draw_frame_asset(color, glow, chaos), f"{style} Rarity frame {name}.", "ui_rarity_frame", log)

    realms = [
        ("mortal", PALETTE["common"]),
        ("qi_refining", PALETTE["teal"]),
        ("foundation", PALETTE["indigo"]),
        ("golden_core", PALETTE["gold"]),
        ("yuanying", PALETTE["purple"]),
        ("huashen", PALETTE["innate"]),
        ("heti", PALETTE["mythic"]),
    ]
    for name, color in realms:
        emit(f"assets/ui/icons/realm/{name}.png", 96, 96, draw_realm_badge(name, color), f"{style} Realm badge {name}.", "ui_realm_badge", log)

    emit("assets/ui/frames/panel_primary.png", 192, 192, draw_panel(PALETTE["panel_bg_primary"], False, True), f"{style} Primary 9-slice panel.", "ui_frame", log)
    emit("assets/ui/frames/panel_secondary.png", 192, 192, draw_panel(PALETTE["panel_bg_secondary"], False, False), f"{style} Secondary 9-slice panel.", "ui_frame", log)
    emit("assets/ui/frames/panel_elevated.png", 192, 192, draw_panel(PALETTE["panel_bg_elevated"], True, True), f"{style} Elevated 9-slice panel.", "ui_frame", log)
    emit("assets/ui/frames/button_states.png", 96, 288, draw_button_states, f"{style} Three-state button sheet.", "ui_frame", log)

    emit("assets/ui/seals/burst_gold.png", 512, 512, draw_seal(PALETTE["gold"], "gold"), f"{style} Gold breakthrough seal.", "ui_seal", log)
    emit("assets/ui/seals/failure_red.png", 512, 512, draw_seal(PALETTE["failure_red"], "failure"), f"{style} Failure seal.", "ui_seal", log)
    emit("assets/ui/seals/ink_default.png", 512, 512, draw_seal(PALETTE["ink"], "ink"), f"{style} Ink decoration seal.", "ui_seal", log)

    emit("assets/characters/player/portrait.png", 512, 768, draw_portrait("player", PALETTE["gold"]), f"{style} Player portrait.", "player", log)
    emit("assets/characters/player/idle_sheet.png", 1024, 1024, draw_sheet(4, 4, "player", PALETTE["gold"], "idle"), f"{style} Player 4x4 idle sheet.", "player", log)
    emit("assets/characters/player/attack_sheet.png", 768, 512, draw_sheet(2, 3, "player", PALETTE["gold"], "attack"), f"{style} Player 2x3 attack sheet.", "player", log)
    emit("assets/characters/player/hurt_sheet.png", 1024, 256, draw_sheet(1, 4, "player", PALETTE["failure_red"], "hurt"), f"{style} Player 1x4 hurt sheet.", "player", log)
    emit("assets/characters/player/death_sheet.png", 768, 512, draw_sheet(2, 3, "player", PALETTE["purple"], "death"), f"{style} Player 2x3 death sheet.", "player", log)

    enemy_specs = [
        ("starter_zone", "mountain_rat", "rat", PALETTE["text_secondary"], (1, 4), (1, 4)),
        ("starter_zone", "forest_wolf", "wolf", PALETTE["common"], (1, 4), (1, 4)),
        ("starter_zone", "low_yao_qi", "smoke", PALETTE["purple"], (2, 2), (1, 4)),
        ("mid_zone", "ghost_flame", "ghost", PALETTE["blue"], (2, 2), (1, 4)),
        ("mid_zone", "cold_corpse", "humanoid", PALETTE["uncommon"], (1, 4), (1, 4)),
        ("mid_zone", "evil_disciple", "humanoid", PALETTE["failure_red"], (1, 4), (1, 4)),
        ("end_zone", "reef_shark", "shark", PALETTE["blue"], (2, 3), (1, 4)),
        ("end_zone", "sea_yao", "humanoid", PALETTE["innate"], (1, 4), (1, 4)),
        ("end_zone", "broken_dragon_shadow", "dragon", PALETTE["purple"], (2, 3), (1, 4)),
    ]
    for zone, name, kind, color, idle_shape, attack_shape in enemy_specs:
        rows, cols = idle_shape
        emit(f"assets/enemies/{zone}/{name}_idle.png", cols * 256, rows * 256, draw_sheet(rows, cols, kind, color, "idle"), f"{style} Enemy {name} idle sheet.", "enemy", log)
        rows, cols = attack_shape
        action = "projectile" if name == "ghost_flame" else "attack"
        suffix = "projectile" if action == "projectile" else "attack"
        emit(f"assets/enemies/{zone}/{name}_{suffix}.png", cols * 256, rows * 256, draw_sheet(rows, cols, kind, color, action), f"{style} Enemy {name} {suffix} sheet.", "enemy", log)
        emit(f"assets/enemies/{zone}/{name}_portrait.png", 256, 256, draw_portrait(kind, color), f"{style} Enemy {name} portrait.", "enemy", log)

    current_enemy_specs = [
        ("training_dummy", "humanoid", PALETTE["legendary"]),
        ("wild_wolf", "wolf", PALETTE["common"]),
        ("mountain_bandit", "humanoid", PALETTE["failure_red"]),
    ]
    for name, kind, color in current_enemy_specs:
        emit(f"assets/enemies/current/{name}_idle.png", 1024, 256, draw_sheet(1, 4, kind, color, "idle"), f"{style} Current MVP enemy {name} idle sheet.", "enemy_current", log)
        emit(f"assets/enemies/current/{name}_attack.png", 1024, 256, draw_sheet(1, 4, kind, color, "attack"), f"{style} Current MVP enemy {name} attack sheet.", "enemy_current", log)
        emit(f"assets/enemies/current/{name}_portrait.png", 256, 256, draw_portrait(kind, color), f"{style} Current MVP enemy {name} portrait.", "enemy_current", log)

    maps = [
        ("main_base", PALETTE["warm_paper"], PALETTE["text_secondary"]),
        ("starter_forest", PALETTE["warm_paper"], PALETTE["herb"]),
        ("ruined_temple", PALETTE["panel_bg_secondary"], PALETTE["purple"]),
        ("east_sea_shore", PALETTE["panel_bg_primary"], PALETTE["blue"]),
        ("town_economy", PALETTE["warm_paper"], PALETTE["gold"]),
    ]
    for name, base, accent in maps:
        emit(f"assets/map/{name}.png", 1920, 1080, draw_map(name, base, accent), f"{style} Background map {name}.", "map", log)
    emit("assets/overlays/failure_grey.png", 1920, 1080, draw_failure_overlay, f"{style} Semi-transparent failure overlay.", "overlay", log)
    emit("assets/overlays/offline_paper.png", 1280, 720, draw_offline_paper, f"{style} Offline reward paper card.", "overlay", log)

    item_specs = [
        ("low_lingshi", PALETTE["jade"]),
        ("mid_lingshi", (0x6F, 0xCF, 0xA0, 255)),
        ("high_lingshi", PALETTE["innate"]),
        ("ling_grass", PALETTE["herb"]),
        ("blood_ginseng", PALETTE["red"]),
        ("sea_pearl", PALETTE["text_primary"]),
        ("low_pill", (0xD4, 0x9C, 0x3A, 255)),
        ("talisman_paper", PALETTE["warm_paper"]),
        ("iron_ore", PALETTE["panel_bg_primary"]),
        ("evil_dust", PALETTE["purple"]),
        ("dragon_scale", PALETTE["blue"]),
        ("pure_qi_crystal", PALETTE["teal"]),
    ]
    for name, color in item_specs:
        emit(f"assets/items/{name}.png", 64, 64, draw_item_icon(name, color), f"{style} Item icon {name}.", "item", log)
    emit("assets/items/item_pack_basic_sheet.png", 768, 768, draw_prop_pack(item_specs[:9], 3, 3), f"{style} Basic 3x3 item prop pack.", "item_pack", log)
    emit("assets/items/item_pack_rare_sheet.png", 512, 512, draw_prop_pack(item_specs[9:], 2, 2), f"{style} Rare 2x2 item prop pack.", "item_pack", log)

    emit("assets/vfx/manual_click_pulse.png", 512, 128, draw_vfx_sheet("ring", 1, 4, PALETTE["teal"], 128, 128), f"{style} Manual click pulse VFX.", "vfx", log)
    emit("assets/vfx/overflow_warn_flash.png", 384, 96, draw_vfx_sheet("warn", 1, 4, PALETTE["red"], 96, 96), f"{style} Overflow warning flash VFX.", "vfx", log)
    emit("assets/vfx/victory_burst_gold.png", 1152, 768, draw_vfx_sheet("burst", 2, 3, PALETTE["gold"], 384, 384), f"{style} Victory burst gold VFX.", "vfx", log)
    emit("assets/vfx/crit_hit_spark.png", 512, 128, draw_vfx_sheet("spark", 1, 4, PALETTE["gold"], 128, 128), f"{style} Critical hit spark VFX.", "vfx", log)
    emit("assets/vfx/level_up_ring.png", 512, 512, draw_vfx_sheet("ring", 2, 2, PALETTE["indigo"], 256, 256), f"{style} Level up ring VFX.", "vfx", log)
    for i, amount in enumerate([0.08, 0.33, 0.66, 1.0], start=1):
        emit(f"assets/vfx/zone_transition_ink_wipe_{i:02d}.png", 1920, 1080, draw_wipe_frame(amount), f"{style} Zone transition ink wipe frame {i}.", "vfx", log)

    (ASSETS / ".generation-log.json").write_text(json.dumps({"version": 1, "entries": log}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return log


def validate_assets(log: list[dict] | None = None) -> dict:
    if log is None:
        log_path = ASSETS / ".generation-log.json"
        log = json.loads(log_path.read_text(encoding="utf-8"))["entries"]
    failures = []
    for entry in log:
        path = ROOT / entry["path"]
        if not path.exists():
            failures.append({"path": entry["path"], "error": "missing"})
            continue
        try:
            width, height, _color_type, alpha = validate_png(path)
        except Exception as exc:  # noqa: BLE001 - validation report should continue.
            failures.append({"path": entry["path"], "error": str(exc)})
            continue
        if width != entry["width"] or height != entry["height"]:
            failures.append({"path": entry["path"], "error": f"dimension {width}x{height} != {entry['width']}x{entry['height']}"})
        alpha_required = {
            "ui_resource_icon",
            "ui_stance_icon",
            "ui_status_icon",
            "ui_rarity_frame",
            "ui_realm_badge",
            "ui_seal",
            "player",
            "enemy",
            "enemy_current",
            "item",
            "item_pack",
            "overlay",
            "vfx",
        }
        if entry["category"] in alpha_required and not alpha and not entry["path"].endswith("zone_transition_ink_wipe_04.png"):
            failures.append({"path": entry["path"], "error": "expected alpha channel content"})
    report = {"checked": len(log), "failures": failures}
    (ROOT / "production" / "qa" / "evidence").mkdir(parents=True, exist_ok=True)
    (ROOT / "production" / "qa" / "evidence" / "asset-validation-report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    log = None if args.validate_only else build_assets()
    report = validate_assets(log)
    if report["failures"]:
        print(json.dumps(report, ensure_ascii=False, indent=2))
        raise SystemExit(1)
    print(f"Generated and validated {report['checked']} MVP asset files.")


if __name__ == "__main__":
    main()
