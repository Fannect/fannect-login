User = require "../../common/models/User"
App = require "../../common/models/App"
redis = require "../../common/utils/redis"
async = require "async"

module.exports =

   load: (obj, cb) ->
      creates = {}
      if obj.users
         creates.users = (done) -> User.create(obj.users, done)

      if obj.apps
         creates.apps = (done) -> App.create(obj.apps, done)

      async.parallel(creates, cb)

   unload: (obj, cb) ->
      user_ids = if obj.users then (u._id for u in obj.users) else []
      app_ids = if obj.apps then (t._id for t in obj.apps) else []
      async.parallel [
         (done) -> User.remove({_id: { $in: user_ids }}, done)
         (done) -> App.remove({_id: { $in: app_ids }}, done)
         (done) -> User.remove({email: "imatester@fannect.me"}, done)
      ], -> cb()





