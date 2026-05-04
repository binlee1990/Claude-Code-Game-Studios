#!/usr/bin/env python3
"""Place a processed image_gen sprite asset into a runtime path with evidence."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--processed-dir", required=True, type=Path)
    parser.add_argument("--output-path", required=True, type=Path)
    parser.add_argument("--asset-id", required=True)
    parser.add_argument("--output-role", required=True)
    parser.add_argument("--prompt-summary", required=True)
    parser.add_argument(
        "--source-file",
        choices=("auto", "clean.png", "sheet-transparent.png"),
        default="auto",
    )
    args = parser.parse_args()

    processed = args.processed_dir
    meta_path = processed / "pipeline-meta.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {}

    if args.source_file == "auto":
        source = processed / ("clean.png" if (processed / "clean.png").exists() else "sheet-transparent.png")
    else:
        source = processed / args.source_file
    if not source.exists():
        raise FileNotFoundError(f"Processed source does not exist: {source}")

    args.output_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, args.output_path)

    with Image.open(args.output_path) as image:
        width, height = image.size

    args.output_path.with_suffix(".prompt.txt").write_text(args.prompt_summary + "\n", encoding="utf-8")
    out_meta = {
        "source": "image_gen",
        "skill": "generate2dsprite",
        "asset_id": args.asset_id,
        "output_role": args.output_role,
        "raw_image": str(meta.get("input", "")).replace("\\", "/"),
        "processed_dir": str(processed.resolve()).replace("\\", "/"),
        "postprocess": "generate2dsprite.py process + place_sprite_output.py",
        "width": width,
        "height": height,
        "processor": {
            "target": meta.get("target"),
            "mode": meta.get("mode"),
            "rows": meta.get("rows"),
            "cols": meta.get("cols"),
            "cell_size": meta.get("cell_size"),
            "single_size": meta.get("single_size"),
            "edge_touch_frames": meta.get("edge_touch_frames", []),
        },
    }
    args.output_path.with_suffix(".pipeline-meta.json").write_text(
        json.dumps(out_meta, indent=2),
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
