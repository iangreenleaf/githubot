[ gh, assert, nock, mock_robot ] = require "./test_helper"

describe "github api", ->
  describe "request", ->
    response = [ { name: "foo", commit: { sha: "abcdef", url: "xxx" } } ]
    network = null
    success = (done) ->
      (body) ->
        network.done()
        done()
    beforeEach ->
      network = nock("https://api.github.com")
        .get("/repos/foo/bar/branches")
        .reply(200, response)
    it "accepts a full url", (done) ->
      gh.get("https://api.github.com/repos/foo/bar/branches") success done
    it "accepts a path", (done) ->
      gh.get("repos/foo/bar/branches") success done
    it "accepts a path (leading slash)", (done) ->
      gh.get("/repos/foo/bar/branches") success done
    it "includes oauth token if exists", (done) ->
      process.env.HUBOT_GITHUB_TOKEN = "789abc"
      network.matchHeader("Authorization", "token 789abc")
      gh.get("/repos/foo/bar/branches") success done
      delete process.env.HUBOT_GITHUB_TOKEN
    it "includes accept header", (done) ->
      network.matchHeader('Accept', 'application/json')
      gh.get("/repos/foo/bar/branches") success done
    it "returns parsed json", (done) ->
      gh.get("/repos/foo/bar/branches") (data) ->
        assert.deepEqual response, data
        done()

  describe "errors", ->
    network = null
    beforeEach ->
      network = nock("https://api.github.com").get("/foo")
    it "complains about bad response", (done) ->
      network.reply(401, message: "Bad credentials")
      gh.get("/foo") ->
        assert.ok /bad credentials/i.exec mock_robot.logs.error.pop()
        done()
    it "complains about client errors", (done) ->
      mock = {
        header: -> mock,
        get: () -> (cb) ->
          cb new Error "Kablooie!"
      }
      http = require "scoped-http-client"
      http._old_create = http.create
      http.create = -> mock
      gh.get("/foo") ->
        assert.ok /kablooie/i.exec mock_robot.logs.error.pop()
        done()
      http.create = http._old_create
