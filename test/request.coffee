assert = require "assert"
nock = require "nock"
gh = require ".."

describe "github api requests", ->
  describe "request", ->
    network = null
    success = (done) ->
      (err, res, body) ->
        throw err if err?
        network.done()
        done()
    beforeEach ->
      network = nock("https://api.github.com")
        .get("/repos/foo/bar/branches")
        .reply(200, [])
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
