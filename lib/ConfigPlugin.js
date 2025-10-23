const { sources, Compilation } = require('webpack');

class ConfigPlugin {
  constructor(options = {}) {
    const { envVars = [], filename = 'config.js' } = options;
    this.filename = filename;

    const envObject = {};
    for (const key of envVars) {
      envObject[key] = process.env[key] ?? null;
    }

    const json = JSON.stringify(envObject, null, 2);
    this.content = `window.ENV = ${json};`;
    this.pluginName = 'ConfigPlugin';
  }

  apply(compiler) {
    compiler.hooks.thisCompilation.tap(this.pluginName, (compilation) => {
      compilation.hooks.processAssets.tap(
        {
          name: this.pluginName,
          stage: Compilation.PROCESS_ASSETS_STAGE_ADDITIONAL,
        },
        () => {
          compilation.emitAsset(
            this.filename,
            new sources.RawSource(this.content)
          );
        }
      );
    });
  }
}

module.exports = ConfigPlugin;
