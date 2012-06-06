# This test does actual API requests against github.
# All others mock out the network activity.
[ gh, assert ] = require "../test_helper"

describe "actual request", ->
  response = [ { name: "foo", commit: { sha: "abcdeg", url: "xxx" } } ]
  success = (done) ->
    (body) ->
      done()
  it "works", (done) ->
    gh.branches "iangreenleaf/githubot", (branches) ->
      assert.ok branches[0].name
      assert.ok branches[0].commit.sha
      assert.ok branches[0].commit.url
      done()
