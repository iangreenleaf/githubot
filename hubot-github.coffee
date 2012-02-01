module.exports = {
  qualified_repo: (repo) ->
    repo = repo.toLowerCase()
    return repo unless repo.indexOf("/") is -1
    unless (user = process.env.HUBOT_GITHUB_USER)?
      robot.logger.error "Default Github user not specified"
      return repo
    "#{user}/#{repo}"
}
