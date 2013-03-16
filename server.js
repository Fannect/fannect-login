/*
Environmental variables
 - PORT
 - MONGO_URL
 - REDIS_URL
*/
if (process.env.NODE_ENV == "production") {
   require("nodefly").profile(
      "8bdbbd3e-684d-4668-aaea-77f52ac9319a",
      ["Fannect Login","Heroku"]
   );
}

require("coffee-script");
app = require("./controllers/host.coffee");
// server = process.env.NODE_ENV == "production" ? require("https") : require("http");
server = require("http");
port = process.env.PORT || 2200;

server.createServer(app).listen(port, function () {
   console.log("Fannect Login API listening on " + port);
});