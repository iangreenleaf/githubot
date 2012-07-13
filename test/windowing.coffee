[ gh, assert, nock, mock_robot ] = require "./test_helper"
http = require "http"

describe "concurrent requests", ->
  before ->
    @port = 7329
    active = 0
    server = http.createServer (req, res) ->
      active++
      assert.ok active <= 20
      setTimeout ->
        active--
        res.end()
      , 10
    server.listen @port
  it "are limited", (done) ->
    remain = 100
    process.env.HUBOT_GITHUB_API = "http://localhost:#{@port}"
    for i in [1..remain]
      gh.request "GET", "/repos/foo/bar/branches/#{i}", ->
        done() if --remain is 0
    delete process.env.HUBOT_GITHUB_API
