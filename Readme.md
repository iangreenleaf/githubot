# A Hubot-compatible Github API wrapper for Node.js #

[![Build Status]](http://travis-ci.org/iangreenleaf/githubot)

## Install ##

    npm install githubot

## Require ##

Use it in your Hubot script:

```coffeescript
module.exports = (robot) ->
  github = require('githubot')(robot)
```

Or use it on its own:

```coffeescript
github = require('githubot')
```

You can pass additional [options](#options) to the constructor if needed.

## Use ##

Make any call to the Github v3 API, get the parsed JSON response:

```coffeescript
github.get "https://api.github.com/users/iangreenleaf/gists", (gists) ->
  console.log gists[0].description

github.get "users/foo/repos", {type: "owner"}, (repos) ->
  console.log repos[0].url

data = { description: "A test gist", public: true, files: { "abc.txt": { content: "abcdefg" } } }
github.post "gists", data, (gist) ->
  console.log gist.url

github.patch "repos/my/repo/issues/11", {status: "closed"}, (issue) ->
  console.log issue.html_url
```

## Authentication ##

If `process.env.HUBOT_GITHUB_TOKEN` is present, you're automatically authenticated. Sweet!

### Acquire a token ###

If you don't have a token yet, run this:

    curl -i https://api.github.com/authorizations -d '{"note":"githubot","scopes":["repo"]}' -u "yourusername"

Enter your Github password when prompted. When you get a response, look for the "token" value.

If you have two-factor authentication enabled, you'll have to append `-H 'X-GitHub-OTP: 123456'` to the end of the above command, or you'll receive HTTP 401 Unauthorized instead of your token.

## Handling errors ##

GitHubot will log errors automatically if it has a logger. Used with Hubot, these will go to the Hubot logger.

If your script would like to catch errors as well, define an extra callback:

```coffeescript
github.handleErrors (response) ->
  console.log "Oh no! #{response.statusCode}!"
```

The callback takes a `response` argument with the following keys:

* `error`: The error message.
* `statusCode`: The status code of the API response, if present.
* `body`: The body of the API response, if present.

You can also pass an error handler in [the options](#available-options) instead.

## Helpful Hubot ##

If `process.env.HUBOT_GITHUB_USER` is present, we can help you guess a repo's full name:

```coffeescript
github.qualified_repo "githubot" # => "iangreenleaf/githubot"
```

This will happen with the bespoke methods as well:

```coffeescript
gh.branches "githubot", (branches) ->
```

## Options ##

### Passing options ###

Options may be passed to githubot in three different ways,
in increasing order of precedence:

1. Through shell environment variables.
2. Through the constructor:

   ```coffeescript
   github = require('githubot')(robot, apiVersion: 'preview')
   ```
3. Using `withOptions`, which lets you pass options to only some requests:

   ```coffeescript
   github = require('githubot')(robot)
   preview = github.withOptions(apiVersion: 'preview')
   # Uses preview API
   preview.get '/preview/feature', -> # ...
   # Uses regular API
   github.get '/regular/feature', -> # ...
   ```

### Available options ###

* `token`/`process.env.HUBOT_GITHUB_TOKEN`:
  GitHub API token. Required to perform authenticated actions.

* `apiVersion`/`process.env.HUBOT_GITHUB_API_VERSION`:
  [Version of the API](http://developer.github.com/v3/versions/)
  to access. Defaults to 'v3'.

* `defaultUser`/`process.env.HUBOT_GITHUB_USER`:
  Default GitHub username to use if one is not given.

* `apiRoot`/`process.env.HUBOT_GITHUB_API`:
  The base API URL. This is useful for Enterprise Github installations.

  For example, `HUBOT_GITHUB_API='https://myprivate.github.int'`

* `concurrentRequests`/`process.env.HUBOT_CONCURRENT_REQUESTS`:
  Limits the allowed number of concurrent requests to the GitHub API. Defaults to 20.

* `errorHandler`:
  Function for custom error handling logic. See [handling errors](#handling-errors) for more details.

## Bespoke API access ##

Mostly a work in progress, but here's a taste of what I have in mind:

### Branches ###
#### List branches ####

```coffeescript
gh.branches "foo/bar", (branches) ->
  console.log branches[0].name
```

#### Create a branch ####

```coffeescript
# Branch from master
gh.branches( "foo/bar" ).create "my_radical_feature", (branch) ->
  console.log branch.sha

# Branch from another branch
gh.branches( "foo/bar" ).create "even_more_radical", from: "my_radical_feature", (branch) ->
  console.log branch.sha
```

#### Merge a branch ####

```coffeescript
# Merge a branch into master
gh.branches( "foo/bar" ).merge "my_radical_feature", (mergeCommit) ->
  console.log mergeCommit.message

# Merge a branch into a different target
gh.branches( "foo/bar" ).merge "my_radical_feature", into: "hotfixes", (mergeCommit) ->
  console.log mergeCommit.message

# `base` is an alias for `into`
gh.branches( "foo/bar" ).merge "my_radical_feature", base: "hotfixes", (mergeCommit) ->
  console.log mergeCommit.message

# Provide your own commit message
gh.branches( "foo/bar" ).merge "my_radical_feature", message: "Merge my radical feature!", (mergeCommit) ->
  console.log mergeCommit.sha
```

#### Delete a branch ####

```coffeescript
gh.branches( "foo/bar" ).delete "my_radical_feature", ->
  console.log "Deleted my branch!"
```

### Deployments ###

*Note*: These methods are smart and automatically use the
`cannonball-preview` version header. No intervention needed!

#### List deployments ####

```coffeescript
gh.deployments "foo/bar", (deploys) ->
  console.log deploys.length
```

#### Create a deployment ####

```coffeescript
gh.deployments("foo/bar")
  .create 'my-branch', payload: {env: 'staging'}, description: "Ship it!", (deploy) =>
    console.log deploy.url
```

#### Deployment statuses ####

```coffeescript
gh.deployments("foo/bar").status deployId, (deploys) ->
  console.log deploys[0].state
```

## Contributing ##

Install the dependencies:

    npm install

Run the tests:

    make test
    make test-all # Runs additional slower "integration" style tests, generally not necessary

**Pull requests encouraged!**

I'm vastly more likely to merge code that comes with tests. If you're confused by the testing process,
ask and I can probably point you in the right direction.

## Thanks ##

[These lovely people have contributed to githubot](https://github.com/iangreenleaf/githubot/contributors).




[Build Status]: https://travis-ci.org/iangreenleaf/githubot.png?branch=master
