http = require "scoped-http-client"

module.exports = {
  qualified_repo: (repo) ->
    repo = repo.toLowerCase()
    return repo unless repo.indexOf("/") is -1
    unless (user = process.env.HUBOT_GITHUB_USER)?
      throw "Default Github user not specified"
    "#{user}/#{repo}"
  get: (url) ->
    if url[0..3] isnt "http"
      url = "/#{url}" unless url[0] is "/"
      url = "https://api.github.com#{url}"
    http.create(url).get()
}
