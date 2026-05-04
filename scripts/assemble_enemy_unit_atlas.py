#!/usr/bin/env python3
"""Assemble a processed 3x3 enemy unit atlas into runtime enemy assets."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

from PIL import Image


def compose_horizontal(paths: list[Path], output: Path) -> None:
    frames = [Image.open(path).convert("RGBA") for path in paths]
    width = sum(frame.width for frame in frames)
    height = max(frame.height for frame in frames)
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = 0
    for frame in frames:
        canvas.paste(frame, (x, 0), frame)
        x += frame.width
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--processed-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--enemy-id", required=True)
    parser.add_argument("--action-name", default="attack")
    parser.add_argument("--prompt-summary", required=True)
    args = parser.parse_args()

    processed = args.processed_dir
    output = args.output_dir
    output.mkdir(parents=True, exist_ok=True)
    meta_path = processed / "pipeline-meta.json"
    meta = json.loads(meta_path.read_text(encoding="utf-8")) if meta_path.exists() else {}
    raw_sheet = str((processed / "raw-sheet.png").resolve()).replace("\\", "/")

    portrait = output / f"{args.enemy_id}_portrait.png"
    idle = output / f"{args.enemy_id}_idle.png"
    action = output / f"{args.enemy_id}_{args.action_name}.png"
    shutil.copy2(processed / "sheet-1.png", portrait)
    compose_horizontal([processed / f"sheet-{index}.png" for index in range(2, 6)], idle)
    compose_horizontal([processed / f"sheet-{index}.png" for index in range(6, 10)], action)

    common_meta = {
        "source": "image_gen",
        "skill": "generate2dsprite",
        "pack": "enemy_unit_atlas_3x3",
        "enemy_id": args.enemy_id,
        "raw_sheet": raw_sheet,
        "postprocess": "generate2dsprite.py process + assemble_enemy_unit_atlas.py",
        "processor": {
            "rows": meta.get("rows", 3),
            "cols": meta.get("cols", 3),
            "cell_size": meta.get("cell_size", 256),
            "edge_touch_frames": meta.get("edge_touch_frames", []),
        },
    }
    outputs = {
        "portrait": {"path": portrait, "width": 256, "height": 256, "cells": [1]},
        "idle": {"path": idle, "width": 1024, "height": 256, "cells": [2, 3, 4, 5]},
        args.action_name: {"path": action, "width": 1024, "height": 256, "cells": [6, 7, 8, 9]},
    }
    for label, payload in outputs.items():
        asset_path = payload["path"]
        prompt_path = asset_path.with_suffix(".prompt.txt")
        meta_out = asset_path.with_suffix(".pipeline-meta.json")
        prompt_path.write_text(args.prompt_summary + "\n", encoding="utf-8")
        item_meta = dict(common_meta)
        item_meta.update(
            {
                "output_role": label,
                "cells": payload["cells"],
                "width": payload["width"],
                "height": payload["height"],
            }
        )
        meta_out.write_text(json.dumps(item_meta, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
