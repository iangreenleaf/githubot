module.exports = (repo, cb) ->
  if cb?
    @get("repos/#{@qualified_repo repo}/pulls", cb)
  else
     pr_merge: (prNumber, opts, cb) =>
      [opts,cb] = [{},opts] unless cb?
      body =
        title: opts.title ? "blank title: added by merge-bot automagically"
        message: opts.message ? "blank message: added by merge-bot automagically"
        squash: opts.squash ? true
      @get "repos/#{@qualified_repo repo}/pulls/#{prNumber}", (json) =>
        body.sha = json.head.merge_commit_sha
        @put "repos/#{@qualified_repo repo}/pulls/#{prNumber}/merge", body, (data) =>
          unless data.sha?
             cb message: data.message
          cb sha: data.sha, message: data.message, merged: data.merged
