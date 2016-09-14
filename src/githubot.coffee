http = require "scoped-http-client"
async = require "async"
querystring = require "querystring"

version = require("../package.json")["version"]

class Github
  constructor: (@logger, @options) ->
    @requestQueue = async.queue (task, cb) =>
      task.run cb
    , @_opt "concurrentRequests"
  withOptions: (specialOptions) ->
    newOpts = {}
    newOpts[k] = v for k,v of @options
    newOpts[k] = v for k,v of specialOptions
    g = new Github @logger, newOpts
    g.requestQueue = @requestQueue
    g
  qualified_repo: (repo) ->
    unless repo?
      unless (repo = @_opt "defaultRepo")?
        @logger.error "Default Github repo not specified"
        return null
    repo = repo.toLowerCase()
    return repo unless repo.indexOf("/") is -1
    unless (user = @_opt "defaultUser")?
      @logger.error "Default Github user not specified"
      return repo
    "#{user}/#{repo}"
  request: (verb, url, data, cb) ->
    unless cb?
      [cb, data] = [data, null]

    url_api_base = @_opt("apiRoot")

    if url[0..3] isnt "http"
      url = "/#{url}" unless url[0] is "/"
      url = "#{url_api_base}#{url}"
    req = http.create(url).header("Accept", "application/vnd.github.#{@_opt "apiVersion"}+json")
    req = req.header("User-Agent", "GitHubot/#{version}")
    oauth_token = @_opt "token"
    req = req.header("Authorization", "token #{oauth_token}") if oauth_token?
    args = []
    args.push JSON.stringify data if data?
    args.push "" if verb is "DELETE" and not data?
    task = run: (cb) -> req[verb.toLowerCase()](args...) cb
    @requestQueue.push task, (err, res, body) =>
      if err?
        return @_errorHandler
          statusCode: res?.statusCode
          body: res?.body
          error: err

      try
        responseData = JSON.parse body if body
      catch e
        return @_errorHandler
          statusCode: res.statusCode
          body: body
          error: "Could not parse response: #{body}"

      if (200 <= res.statusCode < 300)
        cb responseData
      else
        @_errorHandler
          statusCode: res.statusCode
          body: body
          error: responseData.message

  get: (url, data, cb) ->
    unless cb?
      [cb, data] = [data, null]
    if data?
      url += "?" + querystring.stringify data
    @request "GET", url, cb

  post: (url, data, cb) ->
    @request "POST", url, data, cb

  delete: (url, cb) ->
    @request "DELETE", url, null, cb

  put: (url, data, cb) ->
    @request "PUT", url, data, cb

  patch: (url, data, cb) ->
    @request "PATCH", url, data, cb

  handleErrors: (callback) ->
    @options.errorHandler = callback

  _loggerErrorHandler: (response) ->
    message = response.error
    message = "#{response.statusCode} #{message}" if response.statusCode?
    @logger.error message

  _errorHandler: (response) ->
    @options.errorHandler?(response)
    @_loggerErrorHandler response

  branches: require './branches'

  deployments: require './deployments'

  _opt: (optName) ->
    @options ?= {}
    @options[optName] ? @_optFromEnv(optName)
  _optFromEnv: (optName) ->
    switch optName
      when "token"
        process.env.HUBOT_GITHUB_TOKEN
      when "concurrentRequests"
        process.env.HUBOT_CONCURRENT_REQUESTS ? 20
      when "defaultRepo"
        process.env.HUBOT_GITHUB_REPO
      when "defaultUser"
        process.env.HUBOT_GITHUB_USER
      when "apiRoot"
        process.env.HUBOT_GITHUB_API ? "https://api.github.com"
      when "apiVersion"
        process.env.HUBOT_GITHUB_API_VERSION ? "v3"
      else null

module.exports = github = (robot, options = {}) ->
  new Github robot.logger, options

github[method] = func for method,func of Github.prototype

github.logger = {
  error: (msg) ->
    console.error "ERROR: #{msg}"
  debug: ->
}

github.requestQueue = async.queue (task, cb) =>
  task.run cb
, process.env.HUBOT_CONCURRENT_REQUESTS ? 20
