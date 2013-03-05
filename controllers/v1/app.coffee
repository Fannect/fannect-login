express = require "express"
mongoose = require "mongoose"
InvalidArgumentError = require "../../common/errors/InvalidArgumentError"
NotAuthorizedError = require "../../common/errors/NotAuthorizedError"
MongoError = require "../../common/errors/MongoError"
RedisError = require "../../common/errors/RedisError"
auth = require "../../common/middleware/authenticate"
crypt = require "../../common/utils/crypt"
App = require "../../common/models/App"
app = module.exports = express()

# Retrieve access_token and refresh_token (login)
app.post "/v1/apps/token", (req, res, next) ->
   # Validate before querying
   if not req.body?.client_id or not req.body?.client_secret
      return next(new InvalidArgumentError("Required: client_id, client_secret"))
   
   client_id = req.body.client_id
   client_secret = req.body.client_secret

   App.findOne { client_id: client_id, client_secret: client_secret }, (err, app) ->
      return next(new MongoError(err)) if err
      return next(new NotAuthorizedError("Invalid client_id and client_secret")) unless app
      app = app.toObject()
      delete app.client_id
      delete app.client_secret
      auth.createAccessToken app, (err, access_token) ->
         return next(err) if err
         app.access_token = access_token
         res.json app

app.post "/v1/apps", auth.hofStatus, (req, res, next) ->
   name = req.body.name
   return next(new InvalidArgumentError("Required: client_id, client_secret")) unless name

   App.create
      name: name
      client_id: crypt.generateClientId()
      client_secret: crypt.generateClientSecret()
      role: req.body.role or "manager"
   , (err, app) ->
      return next(new MongoError(err)) if err
      app = app.toObject()
      res.json app