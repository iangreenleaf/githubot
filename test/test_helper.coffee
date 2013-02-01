mock_robot =
  logger:
    error: (msg) ->
      mock_robot.logs.error.push msg
      mock_robot.onError(msg) if mock_robot.onError?
    debug: (msg) ->
      mock_robot.logs.debug.push msg
  clean: ->
    mock_robot.onError = null
    mock_robot.logs = { error: [], debug: [] }

gh = require("..") mock_robot
nock = require("nock")
package_version = require("../package.json")["version"]
module.exports = [ gh, require("assert"), nock, mock_robot, package_version ]

beforeEach ->
  nock.cleanAll()
  mock_robot.clean()
