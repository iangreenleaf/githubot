module.exports = (repo, cb) ->
  if cb?
    @get("repos/#{@qualified_repo repo}/pulls", cb)
  else
     merge: (prNumber, opts, cb) =>
      [opts,cb] = [{},opts] unless cb?
      body =
        title: opts.title ? "blank title: added by merge-bot automagically"
        message: opts.message ? "blank message: added by merge-bot automagically"
        squash: opts.squash ? false
      @get "repos/#{@qualified_repo repo}/pulls/#{prNumber}", (json) =>
        body.sha = json.head.merge_commit_sha
        @put "repos/#{@qualified_repo repo}/pulls/#{prNumber}/merge", body, (data) =>
          unless data.sha?
             @_errorHandler error: data.message
          cb sha: data.sha, message: data.message, merged: data.merged
