[ gh, assert, nock, mock_robot ] = require "./test_helper"
http = require "http"

describe "concurrent requests", ->
  it "are limited", (done) ->
    maxRequests = 0
    remain = 100
    port = 7329
    active = 0
    gh = require("..") mock_robot, concurrent_requests: 35

    server = http.createServer (req, res) ->
      active++
      assert.ok active <= 35
      maxRequests = Math.max maxRequests, active
      setTimeout ->
        active--
        res.end()
      , 10
    server.listen port

    process.env.HUBOT_GITHUB_API = "http://localhost:#{port}"
    for i in [1..remain]
      gh.request "GET", "/repos/foo/bar/branches/#{i}", ->
        if --remain is 0
          assert.equal 35, maxRequests
          done()
    delete process.env.HUBOT_GITHUB_API
