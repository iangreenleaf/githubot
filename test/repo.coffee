[ gh, assert, nock, mock_robot ] = require "./test_helper"

describe "repo api", ->
  describe "branches", ->
    response = [ { name: "foo", commit: { sha: "abcdeg", url: "xxx" } } ]
    network = null
    success = (done) ->
      (body) ->
        network.done()
        done()
    beforeEach ->
      network = nock("https://api.github.com")
        .get("/repos/foo/bar/branches")
        .reply(200, response)
    it "accepts a full repo", (done) ->
      gh.branches "foo/bar", success done
    it "accepts an unqualified repo", (done) ->
      process.env.HUBOT_GITHUB_USER = "foo"
      gh.branches "bar", success done
      delete process.env.HUBOT_GITHUB_USER
    it "returns json", (done) ->
      gh.branches "foo/bar", (data) ->
        assert.deepEqual response, data
        done()
    it "allows per-request overrides", (done) ->
      network = nock("https://special.api.dev")
        .get("/repos/bar/baz/branches")
        .reply(200, response)
      gh.withOptions(
          apiRoot: "https://special.api.dev"
          defaultUser: "bar"
          defaultRepo: "baz"
        )
        .branches null, success done
      delete process.env.HUBOT_GITHUB_USER

    describe "create", ->
      beforeEach ->
        @branchName = "newbranch"
        @masterSha = "aaaa9999"
        network = nock("https://api.github.com")
          .get("/repos/foo/bar/git/refs/heads/master")
          .reply(
            200
            , { object: { type: "commit", sha: @masterSha, url: "zzz" }
              , url: "zzz"
              , ref: "refs/heads/master"
            }
          )
          .post("/repos/foo/bar/git/refs",
            ref: "refs/heads/#{@branchName}", sha: @masterSha )
          .reply(
            200
            , { object: { type: "commit", sha: "hijklmn", url: "xxx" }
              , url: "yyy"
              , ref: "refs/heads/#{@branchName}"
            }
          )
      it "returns json", (done) ->
        gh.branches( "foo/bar" ).create @branchName, (data) =>
          assert.deepEqual data,
            name: @branchName, commit: {sha: "hijklmn", url: "xxx"}
          network.done()
          done()

    describe "create from another branch", ->
      beforeEach ->
        @toBranch = "newbranch"
        @fromBranch = "oldbranch"
        @branchSha = "bbbbcccc"
        network = nock("https://api.github.com")
          .get("/repos/foo/bar/git/refs/heads/#{@fromBranch}")
          .reply(
            200
            , { object: { type: "commit", sha: @branchSha, url: "zzz" }
              , url: "zzz"
              , ref: "refs/heads/#{@fromBranch}"
            }
          )
          .post("/repos/foo/bar/git/refs",
            ref: "refs/heads/#{@toBranch}", sha: @branchSha )
          .reply(
            200
            , { object: { type: "commit", sha: "dddd", url: "aaa" }
              , url: "bbb"
              , ref: "refs/heads/#{@toBranch}"
            }
          )
      it "returns json", (done) ->
        gh.branches( "foo/bar" ).create @toBranch, from: @fromBranch, (data) =>
          assert.deepEqual data,
            name: @toBranch, commit: {sha: "dddd", url: "aaa"}
          network.done()
          done()

    describe "delete", ->
      beforeEach ->
        @branchName = "badbranch"
        @response = { object: { type: "commit", sha: "hijklmn", url: "xxx" }, url: "yyy", "ref": "refs/heads/#{@branchName}" }
        network = nock("https://api.github.com")
          .delete("/repos/foo/bar/git/refs/heads/#{@branchName}")
          .reply(204, {})
      it "returns nothing", (done) ->
        gh.branches( "foo/bar" ).delete @branchName, ->
          network.done()
          done()
      it "accepts multiple branch names", (done) ->
        network.delete("/repos/foo/bar/git/refs/heads/anotherBranch")
          .reply(204, {})
        gh.branches( "foo/bar" ).delete @branchName, "anotherBranch", ->
          process.nextTick ->
            network.done()
            done()

    describe "merge", ->
      beforeEach ->
        @branchName = "newbranch"
        @sha = "deadbeef"

      it "succeeds", (done) ->
        network = nock("https://api.github.com")
          .post("/repos/foo/bar/merges",
            base: "master", head: @branchName)
          .reply(
            201
            , sha: @sha, url: "xyz", commit: { message: "commit message" }
          )
        gh.branches("foo/bar").merge @branchName, (commit) =>
          assert.deepEqual commit,
            sha: @sha, message: "commit message", url: "xyz"
          network.done()
          done()

      context "with base specified", (done) ->
        beforeEach ->
          @base = "targetbranch"
          network = nock("https://api.github.com")
            .post("/repos/foo/bar/merges",
              base: @base, head: @branchName)
            .reply(
              201
              , sha: @sha, url: "xyz", commit: { message: "commit message" }
            )
          @cb = (done) => (commit) =>
            assert.deepEqual commit,
              sha: @sha, message: "commit message", url: "xyz"
            network.done()
            done()

        it "as 'into'", (done) ->
          gh.branches("foo/bar").merge @branchName, {into: @base}, @cb(done)
        it "as 'base'", (done) ->
          gh.branches("foo/bar").merge @branchName, {base: @base}, @cb(done)

      it "with commit message specified", (done) ->
        @message = "An awesome merge!"
        network = nock("https://api.github.com")
          .post("/repos/foo/bar/merges",
            base: "master", head: @branchName, commit_message: @message)
          .reply(
            201
            , sha: @sha, url: "xyz", commit: { message: @message }
          )
        gh.branches("foo/bar").merge @branchName, message: @message, (commit) =>
          assert.deepEqual commit,
            sha: @sha, message: @message, url: "xyz"
          network.done()
          done()

      context "when no-op", (done) ->
        beforeEach ->
          network = nock("https://api.github.com")
            .post("/repos/foo/bar/merges",
              base: "master", head: @branchName)
            .reply(204)

        it "errors", (done) ->
          gh.branches("foo/bar").merge @branchName, ->
            assert.fail null, null, "Should not call callback"
          mock_robot.onError = (msg) ->
            assert.ok /nothing to merge/i.exec msg
            network.done()
            done()

        it "notifies custom error handler", (done) ->
          errHandler = (response) ->
            assert.ok /nothing to merge/i.exec response.error
            network.done()
            done()
          gh.withOptions(errorHandler: errHandler).branches("foo/bar").merge @branchName

  describe "deployments", ->
    describe "create deployment", ->
      beforeEach ->
        @branchName = "newbranch"
        @payload = '{"environment":"production","deploy_user":"atmos","room_id":123456}'
        @description = "deploying my sweet branch"

      it "succeeds", (done) ->
        network = nock("https://api.github.com")
          .post("/repos/foo/bar/deployments",
            payload: @payload, ref: @branchName, description: @description)
          .reply(
            201
            , sha: @branchName, url: "xyz/1", description: "abc"
          )
        gh.deployments("foo/bar").create @branchName, {payload: @payload, description: @description}, (status) =>
          assert.deepEqual status,
            sha: @branchName, description: "abc", url: "xyz/1"
          network.done()
          done()

    describe "get deployment status", ->
      beforeEach ->
        @statusId = "123"

      it "succeeds", (done) ->
        network = nock("https://api.github.com")
          .get("/repos/foo/bar/deployments/#{@statusId}/statuses")
          .reply(
            201
            , [{id: @statusId, state: "success", url: "xyz/1", description: "abc"}]
          )
        gh.deployments("foo/bar").status @statusId, (status) =>
          assert.deepEqual status[0],
            id: @statusId, state: "success", url: "xyz/1", description: "abc"
          network.done()
          done()

      it "uses special version header", (done) ->
        network = nock("https://api.github.com")
          .get("/repos/foo/bar/deployments/#{@statusId}/statuses")
          .matchHeader('Accept', 'application/vnd.github.cannonball-preview+json')
          .reply(
            201
            , [{id: @statusId, state: "success", url: "xyz/1", description: "abc"}]
          )
        gh.deployments("foo/bar").status @statusId, (status) ->
          network.done()
          done()
