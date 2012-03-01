[ gh, assert, nock, mock_robot ] = require "./test_helper"

describe "github api", ->
  describe "general purpose", ->
    network = null
    success = (done) ->
      (body) ->
        network.done()
        done()
    describe "request", ->
      response = [ { name: "foo", commit: { sha: "abcdef", url: "xxx" } } ]
      beforeEach ->
        network = nock("https://api.github.com")
          .get("/repos/foo/bar/branches")
          .reply(200, response)
      it "accepts a full url", (done) ->
        gh.request "GET", "https://api.github.com/repos/foo/bar/branches", success done
      it "accepts a path", (done) ->
        gh.request "GET", "repos/foo/bar/branches", success done
      it "accepts a path (leading slash)", (done) ->
        gh.request "GET", "repos/foo/bar/branches", success done
      it "includes oauth token if exists", (done) ->
        process.env.HUBOT_GITHUB_TOKEN = "789abc"
        network.matchHeader("Authorization", "token 789abc")
        gh.request "GET", "repos/foo/bar/branches", success done
        delete process.env.HUBOT_GITHUB_TOKEN
      it "uses basic auth if user/pass exists", (done) ->
        process.env.HUBOT_BOT_GITHUB_USER = "imauser"
        process.env.HUBOT_BOT_GITHUB_PASSWORD = "mypassword"
        network.matchHeader("Authorization", "Basic aW1hdXNlcjpteXBhc3N3b3Jk")
        gh.request "GET", "repos/foo/bar/branches", success done
        delete process.env.HUBOT_BOT_GITHUB_USER
        delete process.env.HUBOT_BOT_GITHUB_PASSWORD
      it "oauth supercedes basic auth", (done) ->
        process.env.HUBOT_GITHUB_TOKEN = "789abc"
        process.env.HUBOT_BOT_GITHUB_USER = "imauser"
        process.env.HUBOT_BOT_GITHUB_PASSWORD = "mypassword"
        network.matchHeader("Authorization", "token 789abc")
        gh.request "GET", "repos/foo/bar/branches", success done
        delete process.env.HUBOT_GITHUB_TOKEN
        delete process.env.HUBOT_BOT_GITHUB_USER
        delete process.env.HUBOT_BOT_GITHUB_PASSWORD
      it "includes accept header", (done) ->
        network.matchHeader('Accept', 'application/json')
        gh.request "GET", "repos/foo/bar/branches", success done
      it "returns parsed json", (done) ->
        gh.request "GET", "repos/foo/bar/branches", (data) ->
          assert.deepEqual response, data
          done()

    describe "get", ->
      beforeEach ->
        network = nock("https://api.github.com")
          .get("/gists")
          .reply(200, [])
      it "sends request", (done) ->
        gh.get "gists", success done

      describe "with params", ->
        beforeEach ->
          network = nock("https://api.github.com")
            .get("/users/foo/repos?foo=bar")
            .reply(200, [])
        it "accepts query params in url", (done) ->
          gh.get "https://api.github.com/users/foo/repos?foo=bar", success done
        it "accepts query params as hash", (done) ->
          gh.get "users/foo/repos", {foo: "bar"}, success done

    describe "post", ->
      data = description: "A test gist", public: true, files: { "abc.txt": { content: "abcdefg" } }
      response = url: "http://api.github.com/gists/1", id: 1
      beforeEach ->
        network = nock("https://api.github.com")
          .post("/gists", data)
          .reply(201, response)
      it "sends request", (done) ->
        gh.post "gists", data, success done

  describe "errors", ->
    network = null
    beforeEach ->
      network = nock("https://api.github.com").get("/foo")
    it "complains about bad response", (done) ->
      network.reply(401, message: "Bad credentials")
      gh.get "/foo", ->
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
      gh.get "/foo", ->
        assert.ok /kablooie/i.exec mock_robot.logs.error.pop()
        done()
      http.create = http._old_create

    describe "without robot given", ->
      before ->
        gh = require("..")
      it "complains to stderr", (done) ->
        util = require "util"
        util._old_error = util.error
        util.error = (msg) ->
          if msg.match /bad credentials/i
            done()
          else
            @_old_error.call process.stderr, msg
        network.reply(401, message: "Bad credentials")
        gh.get "/foo", ->
          util.error = util._old_error
