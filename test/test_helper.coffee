mock_robot = {
  logs: { error: [], debug: [] }
  logger: {
    error: (msg) ->
      mock_robot.logs.error.push msg
      mock_robot.onError(msg) if mock_robot.onError?
    debug: (msg) ->
      mock_robot.logs.debug.push msg
  }
}
gh = require("..") mock_robot
nock = require("nock")
module.exports = [ gh, require("assert"), nock, mock_robot ]

beforeEach ->
  nock.cleanAll()
