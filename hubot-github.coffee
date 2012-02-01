module.exports = {
  qualified_repo: (repo) ->
    repo = repo.toLowerCase()
    return repo unless repo.indexOf("/") is -1
    unless (user = process.env.HUBOT_GITHUB_USER)?
      throw "Default Github user not specified"
    "#{user}/#{repo}"
}
