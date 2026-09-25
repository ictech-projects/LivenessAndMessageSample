#!/usr/bin/env python3
"""
Convert a FaceNet (VGGFace2) face-recognition model to Core ML for
MessageAndLiveness. The resulting model produces an identity embedding that is
far more age/pose/lighting-invariant than the built-in Vision baseline, so a
childhood ID photo can still match an adult selfie.

Once produced, drag `FaceNet.mlpackage` into the app target (Xcode compiles it
to `FaceNet.mlmodelc`). `CoreMLFaceMatcher` auto-detects it — no code changes.

Usage:
    python3 -m venv .venv && source .venv/bin/activate
    pip install torch facenet-pytorch coremltools
    python3 Scripts/convert_face_model.py

Notes:
- FaceNet input is a 160x160 RGB face, normalized (pixel - 127.5) / 128.
- Output is a 512-d, L2-normalized embedding; the app compares with cosine
  similarity.
- For an even stronger model, convert an ArcFace / MobileFaceNet instead and
  name the output MobileFaceNet.mlpackage or ArcFace.mlpackage — the app looks
  for MobileFaceNet, FaceNet, ArcFace, FaceEmbedding (in that order).
"""

import numpy as np
import torch
import coremltools as ct
from facenet_pytorch import InceptionResnetV1

OUTPUT = "FaceNet.mlpackage"
SIZE = 160

def main() -> None:
    print("Loading pretrained FaceNet (VGGFace2)…")
    model = InceptionResnetV1(pretrained="vggface2").eval()

    example = torch.rand(1, 3, SIZE, SIZE)
    traced = torch.jit.trace(model, example)

    # Feed the model an ImageType so Vision/VNCoreMLRequest can hand it a
    # CGImage directly. scale/bias apply (pixel - 127.5)/128 on [0,255] input.
    image_input = ct.ImageType(
        name="image",
        shape=(1, 3, SIZE, SIZE),
        scale=1.0 / 128.0,
        bias=[-127.5 / 128.0, -127.5 / 128.0, -127.5 / 128.0],
        color_layout=ct.colorlayout.RGB,
    )

    print("Converting to Core ML…")
    mlmodel = ct.convert(
        traced,
        inputs=[image_input],
        outputs=[ct.TensorType(name="embedding")],
        minimum_deployment_target=ct.target.iOS16,
        compute_units=ct.ComputeUnit.ALL,
    )

    mlmodel.short_description = "FaceNet (VGGFace2) face embedding for identity matching"
    mlmodel.save(OUTPUT)
    print(f"✅ Saved {OUTPUT}. Add it to the app target in Xcode.")

if __name__ == "__main__":
    main()
