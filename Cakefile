fs            = require 'fs'
{print}       = require 'util'
which         = require 'which'
{spawn, exec} = require 'child_process'
yui           = require 'yuicompressor'
UglifyJS      = require "uglify-js2"

# order of files in `inFiles` is important
config =
  srcDir:  'src'
  outDir:  'lib'
  inFiles: [
    'p3d'
  ]
  outFile: 'p3d'
  yuic:    'yuicompressor'

outJS    = "#{__dirname}/#{config.outDir}/#{config.outFile}"
strFiles = ("#{config.srcDir}/#{file}.coffee" for file in config.inFiles).join ' '

# ANSI Terminal Colors
bold  = '\x1B[0;1m'
red   = '\x1B[0;31m'
green = '\x1B[0;32m'
reset = '\x1B[0m'

log = (message, color, explanation) ->
  console.log color + message + reset + ' ' + (explanation or '')

# deal with errors from child processes
exerr  = (err, sout,  serr)->
  process.stdout.write err  if err
  process.stdout.write sout if sout
  process.stdout.write serr if serr

coffee = (options) ->
  cmd = which.sync 'coffee'
  proc = spawn cmd, options
  proc.stdout.pipe process.stdout
  proc.stderr.pipe process.stderr
  return proc

task 'dev', 'start dev env', ->
  # watch_coffee
  coffee ['-c', '-w', '-o', config.outDir, config.srcDir]
  log 'Watching coffee files', green
  # watch_js
  supervisor = spawn 'node', ['./node_modules/supervisor/lib/cli-wrapper.js','-w','lib,examples/server.js', '-e', 'js|jade', './examples/server']
  supervisor.stdout.pipe process.stdout
  supervisor.stderr.pipe process.stderr
  log 'Watching js files and running example server', green

task 'build', 'join and compile *.coffee files', build = (opts) ->
  log 'Building..', ''
  proc = coffee ["-j", "#{outJS}.js", "-c", "#{strFiles}"]
  proc.on 'exit', (status) -> if status is 0
    log 'Building..           [\x1B[0;32m DONE \x1B[0m]', ''
    opts?.onSuccess?()

task 'min', 'minify compiled *.js file', minify = ->
  log 'Minifying..', ''
  result = UglifyJS.minify "#{outJS}.js"
  fs.writeFile "#{outJS}.min.js", result.code, (err) ->
    if err
      process.stderr.write err
    else
      log 'Minifying..          [\x1B[0;32m DONE \x1B[0m]', ''

task 'bam', 'build and minify', -> build onSuccess: minify
