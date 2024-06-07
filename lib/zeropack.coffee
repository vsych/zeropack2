Webpack = require 'webpack'
WebpackDevServer = require 'webpack-dev-server'
Config = require './webpack.config.coffee'

yellowText = (text) -> "\u001b[33m#{text}\u001b[0m"

console.log yellowText "ZeroPack v#{require("../package.json").version}"

builderCmd = process.argv[2]
builderEnv = process.env['BUILDER_ENV'] || 'development'
builderDir = process.argv[3] || process.cwd()

unless builderCmd in ['build', 'serve', 'watch']
  console.error "Unknown command #{builderCmd}"
  process.exit 1

config = Config(builderCmd, builderEnv, builderDir)
compiler = Webpack config

switch builderCmd
  when 'build'
    compiler.run (err, stats) =>
      console.log stats.toString()
      compiler.close (err) => err && console.error(err)
  when 'watch'
    compiler.watch {}, (err, stats) =>
    if err
      console.error err
      process.exit 1
    console.log stats.toString()
  when 'serve'
    server = new WebpackDevServer config.devServer, compiler
    server.start()
