[ gh, assert, nock, mock_robot ] = require "./test_helper"

describe "commit utilities", ->
  describe "formatting", ->
    summary = "message summary"
    commit =
      sha: "abcdeg"
      url: "https://github.com/foo/bar/commit/abcdeg"
      message: summary + "\n\nmessage body"
    gitio_short = "yyy"
    gitio_url = "http://git.io/" + gitio_short
    network = null
    success = (done) ->
      network.done()
      done()
    it "formats commits with gitio", (done) ->
      network = nock("http://git.io")
        .post("/create")
        .reply(201, gitio_short)
      gh.withOptions(
        gitio: true
        )
        .commits().format commit, (commit) ->
          assert.deepEqual commit.html_url, gitio_url
          success done
    it "formats commits without gitio", (done) ->
      original_url = commit.html_url
      gh.commits().format commit, (commit) ->
        assert.deepEqual commit.html_url, original_url
        done()
    it "formats commits with oneline", (done) ->
      gh.withOptions(
        oneline: true
        )
        .commits().format commit, (commit) ->
          assert.deepEqual commit.message, summary
          done()
    it "formats commits without oneline", (done) ->
      original_message = commit.message
      gh.commits().format commit, (commit) ->
        assert.deepEqual commit.message, original_message
        done()
