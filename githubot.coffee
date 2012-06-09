http = require "scoped-http-client"
querystring = require "querystring"

class Github
  constructor: (@logger) ->
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
    if url[0..3] isnt "http"
      url = "/#{url}" unless url[0] is "/"
      url = "https://api.github.com#{url}"
    req = http.create(url).header("Accept", "application/vnd.github.beta+json")
    req = req.header("Authorization", "token #{oauth_token}") if (oauth_token = process.env.HUBOT_GITHUB_TOKEN)?
    args = []
    args.push JSON.stringify data if data?
    args.push "" if verb is "DELETE" and not data?
    req[verb.toLowerCase()](args...) (err, res, body) =>
      data = null
      if err?
        @logger.error err
      else unless (200 <= res.statusCode < 300)
        @logger.error "#{res.statusCode} #{JSON.parse(body).message}"
      else
        data = JSON.parse body
        cb data
  get: (url, data, cb) ->
    unless cb?
      [cb, data] = [data, null]
    if data?
      url += "?" + querystring.stringify data
    @request "GET", url, cb
  post: (url, data, cb) ->
    @request "POST", url, data, cb
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
        left = branchNames.length
        for branchName in branchNames
          @request "DELETE", "https://api.github.com/repos/#{@qualified_repo repo}/git/refs/heads/#{branchName}", (json) ->
            cb() if --left is 0

module.exports = github = (robot) ->
  new Github robot.logger

github[method] = func for method,func of Github.prototype

github.logger = {
  error: (msg) ->
    util = require "util"
    util.error "ERROR: #{msg}"
  debug: ->
}
