var handler = {}

const express = require("express");
const app = express();

//Disable caching, as this entire server is a long-poll hub
app.use(function(req,res,next) {
	res.header('Cache-Control', 'private, no-cache, no-store, must-revalidate');
	res.header('Expires', '-1');
	res.header('Pragma', 'no-cache');
	next();
});

app.use("/send",function(req,res,next) {
	//Normalize the path so that there is no difference between "/" and ""
	var topic = req.path.replace("/","");

	//To avoid rewriting code, go ahead and define it to avoid errors
	//It won't do anything, but it saves me time and frustration
	if (handler[topic]==undefined) {
		handler[topic]=[];
	}

	//Send back the number of computers currently subscribed to this topic
	res.send(String(handler[topic].length));

	//Parse through each connected client
	for(var i=0;i<handler[topic].length;i++) {
		handler[topic][i].send(req.query.message); //Send data
	}

	//Since all connections have been closed, delete their handlers
	delete handler[topic];
});

app.use("/query",function(req,res,next) {
	//Normalize the path so that there is no difference between "/" and ""
	var topic = req.path.replace("/","");
	//Remove timeout because this could take a while
	res.connection.setTimeout(0);

	//If nobody has registered here yet, create the reference
	if(handler[topic]==undefined) {
		handler[topic] = [];
	}
	handler[topic].push(res); //Add myself to the list
});

app.listen(process.env.PORT || 8080, () => console.log(`Listening on port ${process.env.PORT || 8080}`));
