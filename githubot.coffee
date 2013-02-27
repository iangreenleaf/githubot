http = require "scoped-http-client"
async = require "async"
querystring = require "querystring"

version = require("./package.json")["version"]

process.env.HUBOT_CONCURRENT_REQUESTS ?= 20

class Github
  constructor: (@logger) ->
    @requestQueue = async.queue (task, cb) =>
      task.run cb
    , process.env.HUBOT_CONCURRENT_REQUESTS
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
    req = http.create(url).header("Accept", "application/vnd.github.beta+json")
    req = req.header("User-Agent", "GitHubot/#{version}")
    req = req.header("Authorization", "token #{oauth_token}") if (oauth_token = process.env.HUBOT_GITHUB_TOKEN)?
    args = []
    args.push JSON.stringify data if data?
    args.push "" if verb is "DELETE" and not data?
    task = run: (cb) -> req[verb.toLowerCase()](args...) cb
    @requestQueue.push task, (err, res, body) =>
      return @logger.error err if err?

      try
        data = JSON.parse body if body
      catch e
        return @logger.error "Could not parse response: #{body}"

      if (200 <= res.statusCode < 300)
        cb data
      else
        @logger.error "#{res.statusCode} #{data.message}"
  get: (url, data, cb) ->
    unless cb?
      [cb, data] = [data, null]
    if data?
      url += "?" + querystring.stringify data
    @request "GET", url, cb
  post: (url, data, cb) ->
    @request "POST", url, data, cb
  merge: (repo, base, head, cb) ->
    msg=
      base: base
      head: head
    @post("https://api.github.com/repos/#{@qualified_repo repo}/merges", 
      msg,  cb)
  branches: (repo, cb) ->
    if cb?
      @get("https://api.github.com/repos/#{@qualified_repo repo}/branches", cb)
    else
      create: (branchName, opts, cb) =>
        [opts,cb] = [{},opts] unless cb?
        opts.from ?= "master"
        @get "https://api.github.com/repos/#{@qualified_repo repo}/git/refs/heads/#{opts.from}", (json) =>
          sha = json.object.sha
          @post "https://api.github.com/repos/#{@qualified_repo repo}/git/refs",
            ref: "refs/heads/#{branchName}", sha: sha
            , (data) ->
              cb name: branchName, commit: { sha: data.object.sha, url: data.object.url }
      delete: (branchNames..., cb) =>
        actions = []
        for branchName in branchNames
          do (branchName) =>
            actions.push (done) =>
              @request "DELETE", "https://api.github.com/repos/#{@qualified_repo repo}/git/refs/heads/#{branchName}", done
        async.parallel actions, cb

module.exports = github = (robot) ->
  new Github robot.logger

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
