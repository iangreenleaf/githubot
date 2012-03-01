http = require "scoped-http-client"
querystring = require "querystring"

class Github
  constructor: (@logger) ->
  qualified_repo: (repo) ->
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
    req = http.create(url).header("Accept", "application/json")
    if (oauth_token = process.env.HUBOT_GITHUB_TOKEN)?
      req = req.header("Authorization", "token #{oauth_token}")
    else if process.env.HUBOT_BOT_GITHUB_USER? and process.env.HUBOT_BOT_GITHUB_PASSWORD?
      basic_auth = "#{process.env.HUBOT_BOT_GITHUB_USER}:#{process.env.HUBOT_BOT_GITHUB_PASSWORD}"
      req = req.header("Authorization", "Basic #{new Buffer(basic_auth).toString('base64')}")
    req[verb.toLowerCase()](JSON.stringify data) (err, res, body) =>
      data = null
      if err?
        @logger.error err
      else if res.statusCode != 200
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
    @get("https://api.github.com/repos/#{@qualified_repo repo}/branches", cb)

module.exports = github = (robot) ->
  new Github robot.logger

github[method] = func for method,func of Github.prototype

github.logger = {
  error: (msg) ->
    util = require "util"
    util.error "ERROR: #{msg}"
  debug: ->
}
