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

app.get "/v1/instagram", auth.rookieStatus, (req, res, next) ->
   redirect_uri = "#{instagram_callback}/v1/instagram/callback?user_token=#{req.query.access_token}"
   res.redirect("https://api.instagram.com/oauth/authorize/?client_id=#{client_id}&redirect_uri=#{redirect_uri}&response_type=code")
   
app.get "/v1/instagram/callback", (req, res, next) ->
   return res.redirect "/v1/twitter/done?status=fail" if req.query.error or not req.query.code

   auth.getUser req.query.user_token, (err, user) ->
      if err or not user
         return res.redirect "/v1/twitter/done?status=fail"
   
      request
         url: "https://api.instagram.com/oauth/access_token"
         method: "POST"
         body: querystring.stringify
            client_id: client_id
            client_secret: client_secret
            grant_type: "authorization_code"
            redirect_uri: "#{instagram_callback}/v1/instagram/callback?user_token=#{req.query.user_token}"
            code: req.query.code
      , (err, resp, body) ->
         if err or body.indexOf("access_token") == -1
            return res.redirect "/v1/instagram/done?status=fail"
         
         body = JSON.parse(body)

         user.instagram = body.user
         user.instagram.access_token = body.access_token

         async.parallel
            redis: (done) -> auth.updateUser req.query.user_token, user, done
            mongo: (done) -> User.update {_id: user._id}, { instagram: user.instagram }, done
         , (err, results) ->
            return res.redirect "/v1/instagram/done?status=fail" if err
            res.redirect "/v1/instagram/done?status=success"

app.get "/v1/instagram/done", (req, res, next) ->
   if req.query?.status == "success"
      res.send "Successfully linked Instagram account!"
   else
      res.send "Failed to link Instagram account!"

deleteInstagram = (req, res, next) ->
   delete req.user.instagram

   async.parallel
      redis: (done) -> auth.updateUser req.query.access_token, req.user, done
      mongo: (done) -> User.update { _id: req.user._id }, { "instagram.access_token": null }, done
   , (err) ->
      return next(new MongoError(err)) if err
      res.json status: "success"

app.post "/v1/instagram/delete", auth.rookieStatus, deleteInstagram
app.del "/v1/instagram", auth.rookieStatus, deleteInstagram
   



