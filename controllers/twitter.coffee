express = require "express"
auth = require "../common/middleware/authenticate"
OAuth = require("oauth").OAuth
MongoError = require "../common/errors/MongoError"
RestError = require "../common/errors/RestError"
RedisError = require "../common/errors/RedisError"
InvalidArgumentError = require "../common/errors/InvalidArgumentError"
NotAuthorizedError = require "../common/errors/NotAuthorizedError"

app = module.exports = express()

app.get "/twitter", auth.rookieStatus, (req, res, next) ->
   oa = new OAuth("https://api.twitter.com/oauth/request_token",
      "https://api.twitter.com/oauth/access_token",
      "gFPvxERVpBhfzZh5MNZhQ",
      "xAw41NrcuHoFmdtl45t8tDMgANppe94QnGO0Np3Gak",
      "1.0",
      "http://localhost:2200/twitter/callback/#{req.query.access_token}",
      "HMAC-SHA1")
   
   oa.getOAuthRequestToken (err, oauth_token, oauth_token_secret, results) ->
      return next(new NotAuthorizedError("Failed to authorize Twitter")) if err

      req.user.oauth = {}
      req.user.oauth.token = oauth_token
      req.user.oauth.token_secret = oauth_token_secret

      auth.setUser req.query.access_token, req.user, (err) ->
         return next(new RedisError(err)) if err
         res.redirect("https://twitter.com/oauth/authenticate?oauth_token=#{oauth_token}")

app.get "/twitter/callback/:access_token", (req, res, next) ->
   return next(new NotAuthorizedError("User denied access")) if req.query.denied

   auth.getUser req.params.access_token, (err, user) ->
      return next(err) if err
      return next(new NotAuthorizedError()) unless user

      oa = new OAuth("https://api.twitter.com/oauth/request_token",
         "https://api.twitter.com/oauth/access_token",
         "gFPvxERVpBhfzZh5MNZhQ",
         "xAw41NrcuHoFmdtl45t8tDMgANppe94QnGO0Np3Gak",
         "1.0",
         "http://localhost:2200/twitter/callback/#{req.params.access_token}",
         "HMAC-SHA1")

      verifier = req.query.oauth_verifier

      oa.getOAuthAccessToken user.oauth.token, user.oauth.token_secret, verifier
      , (err, oauth_access_token, oauth_access_token_secret, results) ->
         return next(new InvalidArgumentError(err)) if err

         user.oauth = {} unless user.oauth
         user.oauth.twitter =
            access_token: oauth_access_token
            access_token_secret: oauth_access_token_secret

         console.log user.oauth

         async.parallel
            redis: (done) -> auth.setUser req.query.access_token, user, done
            mongo: (done) -> 
               User.update user._id, {
                  "oauth.twitter.access_token": oauth_access_token
                  "oauth.twitter.access_token_secret": oauth_access_token_secret
               }, done
         , (err) ->
            return next(new RestError(err)) if err 
            res.redirect "forge:///linkAccounts.html"
            # res.json status: "success"




