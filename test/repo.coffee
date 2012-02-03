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
      gh.branches("foo/bar") success done
    it "accepts an unqualified repo", (done) ->
      process.env.HUBOT_GITHUB_USER = "foo"
      gh.branches("bar") success done
      delete process.env.HUBOT_GITHUB_USER
    it "returns json", (done) ->
      gh.branches("foo/bar") (data) ->
        assert.deepEqual response, data
        done()
