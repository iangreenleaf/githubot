# A Hubot-compatible Github API wrapper for Node.js #

## Install ##

    npm install githubot

## Require ##

Use it with Hubot:

```coffeescript
module.exports = (robot) ->
  github = require('githubot')(robot)
```

Or use it on its own:

```coffeescript
github = require('githubot')
```

## Use ##

## General-purpose ##

Make any call to the API, get the parsed JSON response:

```coffeescript
github.get "https://api.github.com/users/iangreenleaf/gists", (gists) ->
  console.log gists[0].description

github.get "users/foo/repos", {type: "owner"}, (repos) ->
  console.log repos[0].url

data = { description: "A test gist", public: true, files: { "abc.txt": { content: "abcdefg" } } }
github.post "gists", data, (gist) ->
  console.log gist.url
```

## Authentication ##

If `process.env.HUBOT_GITHUB_TOKEN` is present, you're automatically authenticated. Sweet!

## Bespoke API access ##

Mostly a work in progress, but here's a taste of what I have in mind:

```coffeescript
gh.branches "foo/bar", (branches) ->
  console.log branches[0].name
```

## Helpful Hubot ##

Hubot will report errors, so that you know what happened.

If `process.env.HUBOT_GITHUB_USER` is present, we can help you guess a repo's full name:

```coffeescript
github.qualified_repo "githubot" # => "iangreenleaf/githubot"
```

This will happen with the bespoke methods as well:

```coffeescript
gh.branches "githubot", (branches) ->
```
