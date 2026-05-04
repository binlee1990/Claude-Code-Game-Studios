#!/usr/bin/env python3
"""Place an image_gen map-like PNG into a runtime path with evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageOps


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output-path", required=True, type=Path)
    parser.add_argument("--asset-id", required=True)
    parser.add_argument("--skill", default="generate2dmap")
    parser.add_argument("--width", required=True, type=int)
    parser.add_argument("--height", required=True, type=int)
    parser.add_argument("--prompt-summary", required=True)
    args = parser.parse_args()

    image = Image.open(args.input).convert("RGBA")
    image = ImageOps.fit(image, (args.width, args.height), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
    args.output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output_path)

    args.output_path.with_suffix(".prompt.txt").write_text(args.prompt_summary + "\n", encoding="utf-8")
    meta = {
        "source": "image_gen",
        "skill": args.skill,
        "asset_id": args.asset_id,
        "raw_image": str(args.input.resolve()).replace("\\", "/"),
        "postprocess": "place_map_output.py cover_resize_center_crop",
        "width": args.width,
        "height": args.height,
    }
    args.output_path.with_suffix(".pipeline-meta.json").write_text(
        json.dumps(meta, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
