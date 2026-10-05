{{flutter_js}}
{{flutter_build_config}}

// tools/build_web.sh fills in the version: main.dart.js and CanvasKit URLs become unique
// per build, so no cache can serve stale code. Empty in development builds.
const buildVersion = '';
const config = {};
if (buildVersion) {
  for (const b of _flutter.buildConfig.builds) {
    if (b.mainJsPath) b.mainJsPath += '?v=' + buildVersion;
  }
  config.canvasKitBaseUrl = 'canvaskit-' + _flutter.buildConfig.engineRevision + '/';
}

// No serviceWorkerSettings: offline caching is handled by our own web/sw.js.
_flutter.loader.load({ config });
