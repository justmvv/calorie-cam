#!/usr/bin/env bash
# Downloads large binaries that are not stored in git into web/:
#   web/ort/     — onnxruntime-web (WASM backend)
#   web/models/  — MobileCLIP-S0 vision encoder (fp16, ~23 MB)
set -euo pipefail
cd "$(dirname "$0")/.."
ORT_VERSION=1.30.0
MODEL_URL=https://huggingface.co/Xenova/mobileclip_s0/resolve/main/onnx/vision_model_fp16.onnx
LICENSE_URL=https://huggingface.co/Xenova/mobileclip_s0/resolve/main/LICENSE

mkdir -p web/ort web/models
for f in ort.wasm.min.js ort-wasm-simd-threaded.wasm ort-wasm-simd-threaded.mjs; do
  [ -s "web/ort/$f" ] || curl -fsSL -o "web/ort/$f" "https://cdn.jsdelivr.net/npm/onnxruntime-web@${ORT_VERSION}/dist/$f"
done
[ -s web/models/vision_model.onnx ] || curl -fsSL -o web/models/vision_model.onnx "$MODEL_URL"
# Apple's license requires redistributing the model together with the license text.
[ -s web/models/LICENSE-MobileCLIP.txt ] || curl -fsSL -o web/models/LICENSE-MobileCLIP.txt "$LICENSE_URL"
ls -la web/ort web/models
