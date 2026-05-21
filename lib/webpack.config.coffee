path                = require 'path'
HtmlWebpackPlugin   = require 'html-webpack-plugin'
TerserPlugin        = require 'terser-webpack-plugin'
Webpack             = require 'webpack'
ConfigPlugin        = require './ConfigPlugin.js'
coffeescript        = require 'coffeescript'
babelCore           = require '@babel/core'

# Built-in CoffeeScript-in-Svelte preprocessor
is_coffee_fragment = (input) ->
  input.attributes?.type == 'coffee' || input.attributes?.lang == 'coffee'

is_typescript_fragment = (input) ->
  input.attributes?.type in ['typescript', 'ts'] ||
    input.attributes?.lang in ['typescript', 'ts']

sveltePreprocess =
  script: (input) ->
    if is_coffee_fragment input
      content = input.content
        .replace /(\$[a-z0-9$]{1,})\s+=/ig, '((v) -> `$1 = v`)'
        .replace /\$\:/g, '$_'
      code = coffeescript.compile content,
        bare: true
        filename: input.filename
      return code: code.replace /\$_/g, '$:'
    if is_typescript_fragment input
      result = babelCore.transformSync input.content,
        filename: "#{input.filename || 'inline'}.ts"
        babelrc: false
        configFile: false
        presets: [require.resolve('@babel/preset-typescript')]
      return code: result.code
    code: input.content

babel =
  loader: 'babel-loader'
  options:
    presets: [
      require.resolve('@babel/preset-env')
      require.resolve('@babel/preset-react')
    ]
    plugins: [
      require.resolve('babel-plugin-add-module-exports')
      require.resolve('@babel/plugin-transform-modules-commonjs')
    ]

babelTS =
  loader: 'babel-loader'
  options:
    presets: [
      require.resolve('@babel/preset-env')
      require.resolve('@babel/preset-react')
      [require.resolve('@babel/preset-typescript'), allExtensions: true, isTSX: true]
    ]
    plugins: [
      require.resolve('babel-plugin-add-module-exports')
      require.resolve('@babel/plugin-transform-modules-commonjs')
    ]

style = loader: 'style-loader'

css = loader: 'css-loader'

thread = loader: 'thread-loader'

file = loader: 'file-loader'

module.exports = (builderCmd, builderEnv, builderDir) ->
  mode = builderCmd == 'serve' && 'development' || 'production'
  if process.env.NODE_ENV == 'production'
    mode = 'production'
  prjPath = path.resolve(builderDir)
  envPath = path.join(prjPath, ".app.data.#{builderEnv}.json")

  builderConfig = require path.join(prjPath, 'zeropack.config.coffee')

  sass =
    loader: 'sass-loader'
    options:
      implementation: builderConfig.sassImplementation || 'node-sass'
      sassOptions: builderConfig.sassOptions || {}

  # Svelte support — enabled when builderConfig.svelte is set
  svelteRule = if builderConfig.svelte
    svelteOpts = Object.assign {dev: mode == 'development', preprocess: sveltePreprocess}, builderConfig.svelte
    [{test: /\.svelte$/, use: {loader: 'svelte-loader', options: svelteOpts}}]
  else []

  # Extensions — auto-add svelte-related when svelte is enabled
  defaultExtensions = ['.coffee', '.ts', '.tsx', '.js', '.cjsx']
  if builderConfig.svelte
    defaultExtensions = ['.mjs', '.js', '.ts', '.tsx', '.svelte', '.coffee']
  extensions = builderConfig.extensions || defaultExtensions

  # Main fields — auto-add 'svelte' when svelte is enabled
  defaultMainFields = ['browser', 'module', 'main']
  if builderConfig.svelte
    defaultMainFields = ['svelte', 'browser', 'module', 'main']
  mainFields = builderConfig.mainFields || defaultMainFields

  mode: mode
  target: builderConfig.target
  devtool: builderConfig.devtool
  entry: builderConfig.entry
  output:
    path: builderConfig.outputPath
    filename: builderConfig.outputFilename || '[fullhash].[name].bundle.js'
    chunkFilename: '[fullhash].[name].[id].chunk.js'
    clean: true
    publicPath: builderConfig.publicPath || '/'
  cache: type: 'filesystem'
  devServer: {
    static: path.join(prjPath, 'public'),
    open: true,
    client: {
      progress: true,
      overlay: mode != 'production'
    },
    ...builderConfig.devServer
  }
  module:
    rules: [
      ...svelteRule
      ...(builderConfig.extraRules || [])
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
        test: /\.(ts|tsx)$/
        exclude: /node_modules/
        use: [
          thread
          babelTS
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
  resolveLoader:
    modules: [
      path.join(__dirname, '..', 'node_modules')
      'node_modules'
    ]
  resolve:
    alias: builderConfig.alias
    extensions: extensions
    mainFields: mainFields
  plugins: [
    new HtmlWebpackPlugin(
      template: builderConfig.htmlTemplate || path.join(prjPath, 'src', 'index.html')
      templateParameters: ENV: APP_ENV: 'production' #TODO: remove after migration to config.js
    ),
    new ConfigPlugin({
      envVars: builderConfig.envVars
    })
    new Webpack.DefinePlugin(Object.assign({'process.env.NODE_ENV': JSON.stringify(mode)}, builderConfig.defines))
    new Webpack.NoEmitOnErrorsPlugin
    ...(builderConfig.extraPlugins || [])
  ].filter(Boolean)
  optimization:
    minimize: mode == 'production'
    minimizer: [ new TerserPlugin ]
