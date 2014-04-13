module.exports = (repo, cb) ->
  # These features are in preview mode
  self = @withOptions apiVersion: 'cannonball-preview'
  if cb?
    self.get("repos/#{self.qualified_repo repo}/deployments", cb)
  else
    create: (branchName, opts, cb) =>
      [opts,cb] = [{},opts] unless cb?
      body =
        ref: branchName ? "master"
      if opts.force?
        body.force = opts.force
      if opts.payload?
        body.payload = opts.payload
      if opts.auto_merge?
        body.auto_merge = opts.auto_merge
      if opts.description?
        body.description = opts.description
      self.post "repos/#{self.qualified_repo repo}/deployments", body, (data) =>
        cb sha: data.sha, description: data.description, url: data.url
    status: (id, cb) =>
      self.get("repos/#{self.qualified_repo repo}/deployments/#{id}/statuses", cb)
