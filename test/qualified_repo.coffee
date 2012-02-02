[ gh, assert, nock ] = require "./test_helper"

describe "qualified_repo", ->
  it "returns full name when given full name", ->
    assert.equal "foo/bar", gh.qualified_repo "foo/bar"
  it "converts to lower case", ->
    assert.equal "foo/bar", gh.qualified_repo "FoO/BAR"
  it "retrieves github username from env", ->
    process.env.HUBOT_GITHUB_USER = "watson"
    assert.equal "watson/bar", gh.qualified_repo "bar"
    delete process.env.HUBOT_GITHUB_USER
  it "complains when no username available", ->
    assert.throws -> gh.qualified_repo "bar"
