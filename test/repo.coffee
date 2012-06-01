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
        @response = { object: { type: "commit", sha: "hijklmn", url: "xxx" }, url: "yyy", "ref": "refs/heads/#{@branchName}" }
        network = nock("https://api.github.com")
          .get("/repos/foo/bar/git/refs/heads/master")
          .reply(200, { object: { type: "commit", sha: @masterSha, url: "xxx" }, url: "yyy", "ref": "refs/heads/master" } )
          .post("/repos/foo/bar/git/refs", {ref: "refs/heads/#{@branchName}", sha: @masterSha } )
          .reply(200, @response )
      it "returns json", (done) ->
        gh.branches( "foo/bar" ).create @branchName, (data) =>
          assert.deepEqual @response, data
          network.done()
          done()

    describe "delete", ->
      beforeEach ->
        @branchName = "newbranch"
        @response = { object: { type: "commit", sha: "hijklmn", url: "xxx" }, url: "yyy", "ref": "refs/heads/#{@branchName}" }
        network = nock("https://api.github.com")
          .delete("/repos/foo/bar/git/refs/heads/#{@branchName}")
          .reply(204)
      it "returns nothing", (done) ->
        gh.branches( "foo/bar" ).delete @branchName, ->
          network.done()
          done()
