express = require "express"
auth = require "../common/middleware/authenticate"
OAuth = require("oauth").OAuth
MongoError = require "../common/errors/MongoError"
RestError = require "../common/errors/RestError"
RedisError = require "../common/errors/RedisError"
InvalidArgumentError = require "../common/errors/InvalidArgumentError"
NotAuthorizedError = require "../common/errors/NotAuthorizedError"
async = require "async"
User = require "../common/models/User"
request = require "request"
querystring = require "querystring"

instagram_callback = process.env.INSTAGRAM_CALLBACK or "http://localhost:2200"

app = module.exports = express()

client_id = "622bb639e3ad4ee99fb3ba0b05c9b847"
client_secret = "551b48dfea2e4a2d9651aa6125f48b39"

app.post "/v1/facebook", auth.rookieStatus, (req, res, next) ->
   return next(new InvalidArgumentError("Required: facebook_access_token"))
   req.user.facebook = {} unless req.user.facebook
   req.user.facebook.access_token = req.body.facebook_access_token

   async.parallel
      redis: (done) -> auth.updateUser req.query.access_token, req.user, done
      mongo: (done) -> User.update { _id: req.user._id }, { "facebook.access_token": req.body.facebook_access_token }, done
   , (err) ->
      return next(new MongoError(err)) if err
      res.json status: "success"

deleteFacebook = (req, res, next) ->
   delete req.user.facebook

   async.parallel
      redis: (done) -> auth.updateUser req.query.access_token, req.user, done
      mongo: (done) -> User.update { _id: req.user._id }, { "facebook.access_token": null }, done
   , (err) ->
      return next(new MongoError(err)) if err
      res.json status: "success"

app.post "/v1/facebook/delete", auth.rookieStatus, deleteFacebook
app.del "/v1/facebook", auth.rookieStatus, deleteFacebook
   



