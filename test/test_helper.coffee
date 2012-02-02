mock_robot = {
  logs: { error: [], debug: [] }
  logger: {
    error: (msg) ->
      mock_robot.logs.error.push msg
    debug: (msg) ->
      mock_robot.logs.debug.push msg
  }
}
gh = require("..") mock_robot
module.exports = [ gh, require("assert"), require("nock"), mock_robot ]
