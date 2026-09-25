# Age-invariant face matching (Core ML model)

The identity flow (`Feature/IdentityVerification`) matches the ID document face
against the liveness selfie via the `FaceMatcher` protocol:

- **Default (no model):** `VisionFeaturePrintFaceMatcher` — Apple's generic
  image feature print. Works out of the box but is **image similarity, not face
  recognition**, so it fails across large age gaps (a childhood ID photo vs an
  adult selfie) and is not KYC-grade.
- **With a model:** `CoreMLFaceMatcher` — a real face-recognition embedding
  (FaceNet / MobileFaceNet / ArcFace). Auto-selected the moment a compiled model
  is in the app bundle. This is what makes child-vs-adult matching work.

## Add the model (turnkey)

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install torch facenet-pytorch coremltools
python3 Scripts/convert_face_model.py     # produces FaceNet.mlpackage
```

Then in Xcode: drag `FaceNet.mlpackage` into the **MessageAndLiveness** target
(check "Copy items if needed" and the app target). Build. Done — the identity
screen will now show matcher name "CoreML face embedding" and match across ages.

`CoreMLFaceMatcher` looks for a compiled model named (in order):
`MobileFaceNet`, `FaceNet`, `ArcFace`, `FaceEmbedding` (`.mlmodelc`). Name your
model accordingly.

## Tuning

The cosine pass threshold is in `CoreMLFaceMatcher.threshold` (default `0.42`,
kept permissive for age tolerance). Lower it to accept larger age gaps, raise it
if you see false accepts. Typical ranges: FaceNet/VGGFace2 ≈ 0.40–0.50,
MobileFaceNet/ArcFace ≈ 0.30–0.45.

## Stronger models

For best accuracy on large age gaps, convert an **ArcFace** model (InsightFace)
or a MobileFaceNet trained with ArcFace loss instead of FaceNet, and save it as
`ArcFace.mlpackage` / `MobileFaceNet.mlpackage`. The Swift side needs no changes.

## Alternative: server / KYC vendor

If on-device accuracy isn't enough for compliance, swap `FaceMatcherFactory` to
a server-backed `FaceMatcher` that posts the two face crops to your backend or a
KYC vendor (Dukcapil, Verihubs/Privy, AWS Rekognition `CompareFaces`) and
returns the score. The rest of the flow is unchanged.
