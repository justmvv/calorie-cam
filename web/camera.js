// In-app camera: a full-screen viewfinder over the Flutter view. The system camera app opened
// by <input capture="environment"> often ignores that hint and starts with the last-used lens
// (e.g. the front one after a selfie); getUserMedia lets us ask for the back camera explicitly.
//
// window.calorieCamera.takePhoto({cancel, switchCamera}) resolves with JPEG bytes (Uint8Array),
// null if the user cancelled, and rejects if the camera can't be used (then Dart falls back to
// the system camera).
(() => {
  const STYLE = `
    .cc-cam { position: fixed; inset: 0; z-index: 2147483647; background: #000; display: flex;
      flex-direction: column; touch-action: none; }
    .cc-cam video { flex: 1; width: 100%; min-height: 0; object-fit: contain; background: #000; }
    .cc-cam .cc-bar { display: flex; align-items: center; justify-content: space-between;
      padding: 18px 28px calc(18px + env(safe-area-inset-bottom)); background: #000; }
    .cc-cam button { font: 500 16px system-ui, sans-serif; color: #fff; background: none; border: 0;
      padding: 12px; min-width: 88px; cursor: pointer; }
    .cc-cam .cc-shutter { width: 72px; height: 72px; min-width: 72px; border-radius: 50%; padding: 0;
      background: #fff; box-shadow: 0 0 0 4px #000, 0 0 0 7px #fff; }
    .cc-cam .cc-shutter:active { transform: scale(0.94); }
    .cc-cam .cc-switch { font-size: 34px; }
  `;

  function stop(stream) { stream?.getTracks().forEach((t) => t.stop()); }

  async function open(facingMode) {
    return navigator.mediaDevices.getUserMedia({
      audio: false,
      video: { facingMode: { ideal: facingMode }, width: { ideal: 1920 }, height: { ideal: 1440 } },
    });
  }

  window.calorieCamera = {
    get available() { return !!navigator.mediaDevices?.getUserMedia; },

    async takePhoto(labels = {}) {
      let facing = 'environment';
      let stream = await open(facing); // throws if denied or no camera: Dart falls back

      if (!document.getElementById('cc-cam-style')) {
        const style = document.createElement('style');
        style.id = 'cc-cam-style';
        style.textContent = STYLE;
        document.head.append(style);
      }
      const root = document.createElement('div');
      root.className = 'cc-cam';
      root.innerHTML = `
        <video autoplay playsinline muted></video>
        <div class="cc-bar">
          <button class="cc-cancel" type="button"></button>
          <button class="cc-shutter" type="button" aria-label="Photo"></button>
          <button class="cc-switch" type="button">\u27F2</button>
        </div>`;
      const video = root.querySelector('video');
      root.querySelector('.cc-cancel').textContent = labels.cancel ?? 'Cancel';
      root.querySelector('.cc-switch').setAttribute('aria-label', labels.switchCamera ?? 'Switch camera');
      document.body.append(root);

      const show = async (s) => { video.srcObject = s; await video.play().catch(() => {}); };
      await show(stream);

      return new Promise((resolve) => {
        const finish = (result) => {
          stop(stream);
          root.remove();
          resolve(result);
        };
        root.querySelector('.cc-cancel').onclick = () => finish(null);
        root.querySelector('.cc-switch').onclick = async () => {
          facing = facing === 'environment' ? 'user' : 'environment';
          stop(stream);
          try {
            stream = await open(facing);
            await show(stream);
          } catch (_) {
            finish(null);
          }
        };
        root.querySelector('.cc-shutter').onclick = async () => {
          const w = video.videoWidth, h = video.videoHeight;
          if (!w || !h) return; // not streaming yet
          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          canvas.getContext('2d').drawImage(video, 0, 0, w, h);
          const blob = await new Promise((r) => canvas.toBlob(r, 'image/jpeg', 0.9));
          finish(new Uint8Array(await blob.arrayBuffer()));
        };
        // The Android back button / Escape closes the camera like "Cancel".
        root.tabIndex = -1;
        root.focus();
        root.onkeydown = (e) => { if (e.key === 'Escape') finish(null); };
      });
    },
  };
})();
