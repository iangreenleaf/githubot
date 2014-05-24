gitio = require "gitio2"

module.exports = (repo, commit, cb) ->
  if cb?
    if commit?
      @get "repos/#{@qualified_repo repo}/commits/#{commit}", cb
    else
      @get "repos/#{@qualified_repo repo}/commits", cb
  else
    format: (commit, cb) =>
      if @_opt "oneline"
        if commit.message?
          commit.message = commit.message.split("\n")[0]
        else if commit.commit? and commit.commit.message?
          commit.message = commit.commit.message.split("\n")[0]
      else if commit.commit? and commit.commit.message? and not commit.message?
        commit.message = commit.commit.message
      if not commit.html_url?
        regex = new RegExp "^#{@_opt "apiRoot"}/(api/#{@_opt "apiVersion"}/)?repos/([^/]+)/([^/]+)/(?:git/)?commits/([a-f0-9]+)$"
        match = commit.url.match regex
        if match?
          api = match[1]
          owner = match[2]
          repo = match[3]
          sha = match[4]
          if api?
            base_url = @_opt "apiRoot"
          else
            base_url = "https://github.com"
          commit.html_url = "#{base_url}/#{owner}/#{repo}/commit/#{sha}"
        else
          console.log "Unmatched commit URL: #{commit.url}"
          commit.html_url = commit.url
      if @_opt "gitio"
        gitio commit.html_url, (err, data) ->
          if not err
            commit.html_url = data
            cb commit
      else
        cb commit
