http = require "scoped-http-client"

module.exports = github = (robot) -> {
  qualified_repo: (repo) ->
    repo = repo.toLowerCase()
    return repo unless repo.indexOf("/") is -1
    unless (user = process.env.HUBOT_GITHUB_USER)?
      robot.logger.error "Default Github user not specified"
      return repo
    "#{user}/#{repo}"
  get: (url) ->
    if url[0..3] isnt "http"
      url = "/#{url}" unless url[0] is "/"
      url = "https://api.github.com#{url}"
    req = http.create(url).header("Accept", "application/json")
    req = req.header("Authorization", "token #{oauth_token}") if (oauth_token = process.env.HUBOT_GITHUB_TOKEN)?
    return (cb) ->
      req.get() (err, res, body) ->
        data = null
        if err?
          robot.logger.error err
        else if res.statusCode != 200
          robot.logger.error "#{res.statusCode} #{JSON.parse(body).message}"
        else
          data = JSON.parse body
        cb data
  branches: (repo) ->
    @get("https://api.github.com/repos/#{@qualified_repo repo}/branches")
}
