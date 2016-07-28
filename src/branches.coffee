async = require "async"

module.exports = (repo, cb) ->
  if cb?
    @get("repos/#{@qualified_repo repo}/branches", cb)
  else
    create: (branchName, opts, cb) =>
      [opts,cb] = [{},opts] unless cb?
      opts.from ?= "master"
      @get "repos/#{@qualified_repo repo}/git/refs/heads/#{opts.from}", (json) =>
        sha = json.object.sha
        @post "repos/#{@qualified_repo repo}/git/refs",
          ref: "refs/heads/#{branchName}", sha: sha
          , (data) ->
            cb name: branchName, commit: { sha: data.object.sha, url: data.object.url }
    delete: (branchNames..., cb) =>
      actions = []
      for branchName in branchNames
        do (branchName) =>
          actions.push (done) =>
            @request "DELETE", "repos/#{@qualified_repo repo}/git/refs/heads/#{branchName}", done
      async.parallel actions, cb
    merge: (head, opts, cb) =>
      [opts,cb] = [{},opts] unless cb?
      body =
        base: opts.base ? opts.into ? "master"
        head: head
      if opts.message?
        body.commit_message = opts.message
      @post "repos/#{@qualified_repo repo}/merges", body, (data) =>
        unless data?
          return @_errorHandler
            error: "Nothing to merge"
        cb sha: data.sha, message: data.commit.message, url: data.url
