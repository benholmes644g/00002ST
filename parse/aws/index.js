var express = require('express');
var ParseServer = require('parse-server').ParseServer;
var app = express();

var api = new ParseServer({
  databaseURI: 'mongodb://admin:QWERTYUIOP@ds011734.mlab.com:11734/dev', // Connection string for your MongoDB database
  cloud: '/home/parse/cloud/main.js', // Absolute path to your Cloud Code
  appId: 'com.sidetone.net',
  masterKey: 'QWERTYUIOP123456', // Keep this key secret!
  fileKey: 'optionalFileKey',
  serverURL: 'http://parseserver-crdwp-env.us-east-1.elasticbeanstalk.com/parse' // Don't forget to change to https if needed
});

// Serve the Parse API on the /parse URL prefix
app.use('/parse', api);

app.listen(1337, function() {
  console.log('parse-server running on port 1337.');
});
