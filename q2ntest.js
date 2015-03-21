// Tests quote2note running at hostName by sending a request
// with a random stock symbol up to maxLength characters long
// or by sending a /show request
//
// Node.js code (to learn something new!)
// (c)2015 Larry Lang

hostName = 'quote2note.YOURHOST.COM';
maxLength = 4;

var randomNumber = function(lower_bound, upper_bound)
{
    //returns random integer between lower and upper bound
    return Math.round(Math.random()*(upper_bound - lower_bound) + lower_bound);
}

var randomSymbol = function(length)
{
    //returns random symbol with length letters
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    var text = "";
    for( var i=0; i < length; i++ )
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    return text;
}

symbol = randomSymbol(randomNumber(0,maxLength));
if (symbol.length > 0) {
    console.log("q2ntest: Sending request with random symbol "+symbol);
    urlPath = '/action?symbol='+symbol;
}
else{
    console.log("q2ntest: Sending /show request");
    urlPath = '/show';
}

var http = require('http');
//remember to install via
//npm install http

var options =
{
host: hostName,
path: urlPath,
method: 'GET',
port: 80,
headers: {
    'User-Agent': 'q2ntest Agent/1.0'
}
};

var callback = function(response) {
    console.log("q2ntest: HTTP status code " + response.statusCode);
    var str = '';
    //another chunk of data has been received, so append it to `str`
    response.on('data', function (chunk) {
                str += chunk;
                });
    //the whole response has been received, so we just print it out here
    response.on('end', function () {
                // uncomment to send full HTTP response to console
                // console.log(str);
                });
}

http.request(options, callback).end();
