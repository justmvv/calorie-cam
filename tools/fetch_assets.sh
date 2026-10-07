#!/usr/bin/env bash
# Downloads large binaries that are not stored in git into web/:
#   web/ort/     — onnxruntime-web (WASM backend)
#   web/models/  — MobileCLIP-S2 vision encoder (fp16, ~72 MB)
set -euo pipefail
cd "$(dirname "$0")/.."
ORT_VERSION=1.30.0
MODEL_URL=https://huggingface.co/Xenova/mobileclip_s2/resolve/main/onnx/vision_model_fp16.onnx
LICENSE_URL=https://huggingface.co/Xenova/mobileclip_s2/resolve/main/LICENSE

mkdir -p web/ort web/models
# Two runtimes: the WebGPU build (GPU, with a CPU fallback inside) for browsers with WebGPU, and
# the lighter WASM-only build for the rest; web/index.html picks one.
for f in ort.wasm.min.js ort-wasm-simd-threaded.wasm ort-wasm-simd-threaded.mjs \
         ort.webgpu.min.js ort-wasm-simd-threaded.asyncify.wasm ort-wasm-simd-threaded.asyncify.mjs; do
  [ -s "web/ort/$f" ] || curl -fsSL -o "web/ort/$f" "https://cdn.jsdelivr.net/npm/onnxruntime-web@${ORT_VERSION}/dist/$f"
done
# The file name stays the same across models: re-download when the source URL changed.
if [ "$(cat web/models/source.txt 2>/dev/null)" != "$MODEL_URL" ]; then
  curl -fsSL -o web/models/vision_model.onnx "$MODEL_URL"
  echo "$MODEL_URL" > web/models/source.txt
  rm -f web/models/LICENSE-MobileCLIP.txt
fi
# Apple's license requires redistributing the model together with the license text.
[ -s web/models/LICENSE-MobileCLIP.txt ] || curl -fsSL -o web/models/LICENSE-MobileCLIP.txt "$LICENSE_URL"
ls -la web/ort web/models
