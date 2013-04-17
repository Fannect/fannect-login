express = require "express"
path = require "path"
mongoose = require "mongoose"
mongooseTypes = require "mongoose-types"
redis = require "../common/utils/redis"
client = redis(process.env.REDIS_URL or "redis://redistogo:f74caf74a1f7df625aa879bf817be6d1@perch.redistogo.com:9203")
queue = redis(process.env.REDIS_QUEUE_URL or "redis://redistogo:f74caf74a1f7df625aa879bf817be6d1@perch.redistogo.com:9203", "queue")
ResourceNotFoundError = require "../common/errors/ResourceNotFoundError"

app = module.exports = express()

# Settings
app.configure "development", () ->
   app.use express.logger "dev"
   app.use express.errorHandler { dumpExceptions: true, showStack: true }

app.configure "production", () ->
   app.use express.errorHandler()

# Middleware
app.use express.query()
app.use express.bodyParser()
app.use express.static path.join __dirname, "../public"

# Set up mongoose
mongoose.connect process.env.MONGO_URL or "mongodb://halloffamer:krzj2blW7674QGk3R1ll967LO41FG1gL2Kil@linus.mongohq.com:10045/fannect-dev"
# mongoose.connect process.env.MONGO_URL or "mongodb://halloffamer:krzj2blW7674QGk3R1ll967LO41FG1gL2Kil@fannect-production.member0.mongolayer.com:27017/fannect-production"
mongooseTypes.loadTypes mongoose

# Controllers
app.use require "./v1"
app.use require "./twitter"
app.use require "./instagram"
app.use require "./facebook"

app.all "*", (req, res, next) ->
   next(new ResourceNotFoundError())

# Error handling
app.use require "../common/middleware/handleErrors"
