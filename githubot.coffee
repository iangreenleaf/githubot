http = require "scoped-http-client"
async = require "async"
querystring = require "querystring"

version = require("./package.json")["version"]

process.env.HUBOT_CONCURRENT_REQUESTS ?= 20

class Github
  constructor: (@logger, @options) ->
    @requestQueue = async.queue (task, cb) =>
      task.run cb
    , process.env.HUBOT_CONCURRENT_REQUESTS
  withOptions: (specialOptions) ->
    newOpts = {}
    newOpts[k] = v for k,v of @options
    newOpts[k] = v for k,v of specialOptions
    g = new @constructor @logger, newOpts
    g.requestQueue = @requestQueue
    g
  qualified_repo: (repo) ->
    unless repo?
      unless (repo = process.env.HUBOT_GITHUB_REPO)?
        @logger.error "Default Github repo not specified"
        return null
    repo = repo.toLowerCase()
    return repo unless repo.indexOf("/") is -1
    unless (user = process.env.HUBOT_GITHUB_USER)?
      @logger.error "Default Github user not specified"
      return repo
    "#{user}/#{repo}"
  request: (verb, url, data, cb) ->
    unless cb?
      [cb, data] = [data, null]

    url_api_base = process.env.HUBOT_GITHUB_API || "https://api.github.com"

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
    @_errorHandler = (response) =>
      callback response
      @_loggerErrorHandler response

  _loggerErrorHandler: (response) ->
    message = response.error
    message = "#{response.statusCode} #{message}" if response.statusCode?
    @logger.error message

  _errorHandler: (response) ->
    @_loggerErrorHandler response

  branches: (repo, cb) ->
    if cb?
      @get("repos/#{@qualified_repo repo}/branches", cb)
    else
      create: (branchName, opts, cb) =>
        [opts,cb] = [{},opts] unless cb?
        opts.from ?= "master"
        @get "repos/#{@qualified_repo repo}/git/refs/heads/#{opts.from}", (json) =>
          sha = json.object.sha
          @post "repos/#{@qualified_repo repo}/git/refs",
            ref: "refs/heads/#{branchName}", sha: sha
            , (data) ->
              cb name: branchName, commit: { sha: data.object.sha, url: data.object.url }
      delete: (branchNames..., cb) =>
        actions = []
        for branchName in branchNames
          do (branchName) =>
            actions.push (done) =>
              @request "DELETE", "repos/#{@qualified_repo repo}/git/refs/heads/#{branchName}", done
        async.parallel actions, cb
      merge: (head, opts, cb) =>
        [opts,cb] = [{},opts] unless cb?
        body =
          base: opts.base ? opts.into ? "master"
          head: head
        if opts.message?
          body.commit_message = opts.message
        @post "repos/#{@qualified_repo repo}/merges", body, (data) =>
          unless data?
            return @logger.error "Nothing to merge"
          cb sha: data.sha, message: data.commit.message, url: data.url

  deployments: (repo, cb) ->
    if cb?
      @get("repos/#{@qualified_repo repo}/deployments", cb)
    else
      create: (branchName, opts, cb) =>
        [opts,cb] = [{},opts] unless cb?
        body =
          ref: branchName ? "master"
        if opts.force?
          body.force = opts.force
        if opts.payload?
          body.payload = opts.payload
        if opts.auto_merge?
          body.auto_merge = opts.auto_merge
        if opts.description?
          body.description = opts.description
        @post "repos/#{@qualified_repo repo}/deployments", body, (data) =>
          cb sha: data.sha, description: data.description, url: data.url
      status: (id, cb) =>
        @get("repos/#{@qualified_repo repo}/deployments/#{id}/statuses", cb)

  _opt: (optName) ->
    @options ?= {}
    @options[optName] ? @_optFromEnv(optName)
  _optFromEnv: (optName) ->
    switch optName
      when "token" then process.env.HUBOT_GITHUB_TOKEN
      else null

module.exports = github = (robot, options = apiVersion: 'beta') ->
  new Github robot.logger, options

github[method] = func for method,func of Github.prototype

github.logger = {
  error: (msg) ->
    util = require "util"
    util.error "ERROR: #{msg}"
  debug: ->
}

github.requestQueue = async.queue (task, cb) =>
  task.run cb
, process.env.HUBOT_CONCURRENT_REQUESTS
