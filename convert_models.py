import os
import sys
from pathlib import Path

MODELS = ["best.pt", "v1.pt", "v2.pt"]
IMGSZ = 640


def convert(pt: Path) -> bool:
    from ultralytics import YOLO

    try:
        import torch

        ckpt = torch.load(str(pt), map_location="cpu", weights_only=False)
        if isinstance(ckpt, dict) and "model" not in ckpt:
            print(
                f"[skip] {pt.name} is a raw state_dict (custom architecture) - "
                "needs its original model class to export."
            )
            return False
    except Exception:
        pass

    out = pt.with_suffix(".onnx")
    print(f"[convert] {pt.name} -> {out.name}")
    last_error = None

    for kwargs in ({"task": "pose"}, {}):
        try:
            model = YOLO(str(pt), **kwargs) if kwargs else YOLO(str(pt))
            exported = model.export(
                format="onnx",
                imgsz=IMGSZ,
                opset=12,
                dynamic=False,
                simplify=False,
            )
            exported_path = Path(exported)
            if exported_path.exists():
                print(f"[ok] {exported_path.name}")
                return True
            if out.exists():
                print(f"[ok] {out.name}")
                return True
        except Exception as exc:
            last_error = exc
            label = kwargs.get("task", "auto")
            print(f"  retry ({label}): {exc}")

    print(f"[fail] {pt.name}: {last_error}")
    return False


def main() -> int:
    root = Path(__file__).resolve().parent
    os.chdir(root)

    found = False
    failed = False

    for name in MODELS:
        pt = root / name
        if not pt.exists():
            print(f"[skip] {name} not found")
            continue

        found = True
        onnx = pt.with_suffix(".onnx")
        if onnx.exists() and onnx.stat().st_mtime >= pt.stat().st_mtime:
            print(f"[skip] {onnx.name} is up to date")
            continue

        if not convert(pt):
            failed = True

    if not found:
        print("[warn] no .pt models found next to setup.bat")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
