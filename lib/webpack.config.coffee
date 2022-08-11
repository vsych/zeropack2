path                = require 'path'
HtmlWebpackPlugin   = require 'html-webpack-plugin'
TerserPlugin        = require 'terser-webpack-plugin'

babel =
  loader: 'babel-loader'
  options:
    presets: [
      '@babel/preset-env'
      '@babel/preset-react'
    ]
    plugins: [
      'add-module-exports'
      '@babel/plugin-transform-modules-commonjs'
    ]

style = loader: 'style-loader'

css = loader: 'css-loader'

sass =
  loader: 'sass-loader'
  options: implementation: 'node-sass'

thread = loader: 'thread-loader'

file = loader: 'file-loader'

module.exports = (builderCmd, builderEnv, builderDir) ->
  mode = builderCmd == 'serve' && 'development' || 'production'
  prjPath = path.resolve(builderDir)

  builderConfig = require path.join(prjPath, 'zeropack.config.coffee')

  mode: mode
  entry: builderConfig.entry
  output:
    path: builderConfig.outputPath
    filename: '[fullhash].[name].bundle.js'
    chunkFilename: '[fullhash].[name].[id].chunk.js'
    clean: true
    publicPath: builderConfig.publicPath || '/'
  cache: type: 'filesystem'
  devServer: {
    static: path.join(prjPath, 'public'),
    open: true,
    client: {
      progress: true
    },
    ...builderConfig.devServer
  }
  module:
    rules: [
      {
        test: /\.scss$/
        use: [
          thread
          style
          css
          sass
        ]
      }
      {
        test: /\.css$/
        use: [
          thread
          style
          css
        ]
      }
      {
        test: /\.(coffee|cjsx)$/
        use: [
          thread
          babel
          { loader: 'coffee-loader' }
        ]
      }
      {
        test: /\.?js$/
        exclude: /node_modules/
        use: [
          thread
          babel
        ]
      }
      {
        test: /\.(ttf|eot|svg|png|jpg|jpeg|gif|woff(2)?)(\?[a-z0-9=&.]+)?$/
        type: 'asset/resource'
      }
    ]
  resolve:
    alias: builderConfig.alias
    extensions: [
      '.coffee'
      '.js'
      '.cjsx'
    ]
  plugins: [ new HtmlWebpackPlugin(
    template: path.join(prjPath, 'src', 'index.html')
    templateParameters: ENV: require(path.join(prjPath, ".app.data.#{builderEnv}.json"))) ]
  optimization:
    minimize: mode == 'production'
    minimizer: [ new TerserPlugin ]
