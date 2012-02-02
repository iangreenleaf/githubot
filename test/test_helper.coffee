mock_robot = {
  logger: {
    error: (msg) ->
    debug: (msg) ->
  }
}
gh = require("..") mock_robot
module.exports = [ gh, require("assert"), require("nock") ]
