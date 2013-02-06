var express = require('express');
var watch = require("watch");
var app = express();
var fs = require('fs');

watch.watchTree(__dirname + '/../lib/', {ignoreDotFiles: true}, function (files, curr, prev) {
  console.log("Copying js to ./examples/js/");
  fs.readdir(__dirname + '/../lib/', function(err, files) {
    for (i in files) {
      var f = files[i];
      if (f.match(/^\./)) continue;
      fs.createReadStream(__dirname + '/../lib/' + f).pipe(fs.createWriteStream(__dirname + '/js/' + f));
    }
  });
  console.log("Copying js to ./examples/js/   [\x1B[0;32m DONE \x1B[0m]");
});


app.use('/', express.static(__dirname + '/'));

port = process.env.PORT || process.env.VMC_APP_PORT || 3033
// Start Server
app.listen(port, function() {
  console.log("Listening on "+port+"\nPress CTRL-C to stop server.");
});
