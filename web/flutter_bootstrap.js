{{flutter_js}}
{{flutter_build_config}}

// tools/build_web.sh fills in the version: main.dart.js, the assets folder and CanvasKit get
// URLs unique to the build, so no cache can mix files from different releases.
// Empty in development builds.
const buildVersion = '';
const config = {};
if (buildVersion) {
  for (const b of _flutter.buildConfig.builds) {
    if (b.mainJsPath) b.mainJsPath += '?v=' + buildVersion;
  }
  config.canvasKitBaseUrl = 'canvaskit-' + _flutter.buildConfig.engineRevision + '/';
  config.assetBase = 'b-' + buildVersion + '/';
}

// No serviceWorkerSettings: offline caching is handled by our own web/sw.js.
_flutter.loader.load({ config });
