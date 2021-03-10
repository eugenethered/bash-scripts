// node server to serve files from dir
// TIP: don't use relative paths, rather full paths

var connect = require('connect');
var serveStatic = require('serve-static');

var source_dir_arg = process.argv[2];
var serve_from_dir = String(source_dir_arg);

console.log('attempting to serve files from:' + serve_from_dir);

connect().use(serveStatic(serve_from_dir)).listen(8080, function(){
    console.log('Server running on 8080...');
});


