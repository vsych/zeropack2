require('dotenv').config();
Webpack = require 'webpack'
WebpackDevServer = require 'webpack-dev-server'
Config = require './webpack.config.coffee'
Express = require 'express'
Path = require 'path'

greenText = (text) -> "\u001b[32m#{text}\u001b[0m"

console.log greenText "ZeroPack v#{require("../package.json").version}"

builderCmd = process.argv[2]
builderEnv = process.env['BUILDER_ENV'] || 'development'
builderDir = process.argv[3] || process.cwd()

unless builderCmd in ['build', 'serve', 'watch', 'server']
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
  when 'server'
    # Get the build output path from config
    buildPath = config.output.path
    port = process.env.PORT || 3000
    host = process.env.HOST || 'localhost'

    app = Express()

    # Serve static files from the build directory
    app.use Express.static(buildPath)

    # Handle client-side routing by serving index.html for all routes
    app.get '/*any', (req, res) ->
      res.sendFile Path.join(buildPath, 'index.html')

    app.listen port, host, ->
      console.log greenText "Server running at http://#{host}:#{port}"
      console.log greenText "Serving static files from: #{buildPath}"
