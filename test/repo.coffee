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
          network.done()
          done()
