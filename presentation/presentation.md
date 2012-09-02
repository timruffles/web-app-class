# Web app

## What does a web app do

Provides the HTML a user sees

By: 

- identifying user
- reloading their data
- generating HTML (or other formats)

## Server

Does what you'd think: 'serves up' something to the browser

HTML

## HTML

Just a plain text file sent over the wire. Arrives, and the browser may trigger additional requests for non-inlined resources

eg:
- images
- videos
- sounds
- CSS, Javascript

## URLs

<table>
	<tr>
		<td>http://</td><td>www</td><td>.google</td><td>.com</td><td>/search.html</td><td>?q=foo</td>
  </tr>
	<tr>
		<td>protocol</td><td>subdomain</td><td>domain</td><td>tld</td><td>path</td><td>query string</td>
	</tr>
</table>

## Identifying a server

Name is looked up via the Domain Name System, giving an IP of a server.

Server takes the request, reads the URL and any data POSTed, and replies.

Request and respose are made up of HTTP headers, and optionally some data.

## Simplified story

You want google, you ask for `http://www.google.co.uk/404.html`

DNS tells the browser to connect to `173.194.34.128`.

You send 

		GET / HTTP/1.1
		Host: www.google.co.uk

You get 

	<!DOCTYPE html>
	<html lang=en>
		<meta charset=utf-8>
		<meta name=viewport content="initial-scale=1, minimum-scale=1, width=device-width">
		<title>Error 404 (Not Found)!!1</title>
		<style>
			/* style */
		</style>
		<a href=//www.google.com/><img src=//www.google.com/images/errors/logo_sm.gif alt=Google></a>
		<p><b>404.</b> <ins>That’s an error.</ins>
		<p>The requested URL <code>/404.html</code> was not found on this server.  <ins>That’s all we know.</ins>

## Then

Your browser sees
		
		<img src=//www.google.com/images/errors/logo_sm.gif alt=Google></a>

so it sends

		GET /images/errors/logo_sm.gif HTTP/1.1
		Host: www.google.com

and receives the image

## So what does a web app do?

It receives from the server data sent by the client (normally a browser), and provides a response which the server serves up to the client.

How? The simplest possible web app might be something like 

		GET /answer.html HTTP/1.1
		Host: http://meaningoflife.com

web app code

		if path == "/answer.html"
			respond "<h1>42, obviously</h1>"
		end

server gives the app code the `path` - "/answer.html" as a variable. The app code reads the variables, and fires a `respond` function that passes a response to the server. This is then served up as:

		HTTP/1.1 200 OK
		Content-Type: text/html; charset=UTF-8 
		Content-Length: 42
		
		<h1>42 is quite obviously the answer.</h1>

## So

Our task is to take all the data sent over HTTP by a client, and respond with some HTML.

Static files (images, CSS, JS, videos) are normally served by a server.

We're going to do that using Ruby.

## Ruby

Ruby is a nice language made by a nice person:

"I hope to see Ruby help every programmer in the world to be productive, and to enjoy programming, and to be happy"

It looks like this

		description = "ruby is fun"
		backwards = description.reverse
    
		# this is a comment, the computer can't see us here (haha, dumb computer)
		# so we can leave ourselves notes about what's going to happen
		# like that the next line will print "nuf si ybur" to the screen
		puts backwards

## Fundamentals of programming

Store things in variables.

		programming = "fun"

Make decisions

		while programming == "fun"
			puts "yay"
			sleep 1	
		end

Logic
		
		if (Monday..Thursday).include?(today)
			puts "boo"
		else
			puts "yay!"
		end

## Functions

Functions are like black boxes you can reuse in your code. You put things into them and get things out.

		def add(a,b)
			return a + b
		end

You 'call' a function with arguments. The interpreter looks up the name, assigns the arguments inside the function, runs it, and returns with the return value to where it was called.

		def circumference(r)
			Math.PI * 2 * r
		end

		radius = 5
		circum = circumference(radius)
		puts "the circle's circumference is #{circum}"

## Data

Inside our programs we keep data in data structures.

		cats = ["tabby","persian","calico"]
		hello = {
			"fr" => "bonjour",
			"en" => "hello",
			"th" => "สวัสดี"
		}

We just met the two you'll be using in Ruby - `Array` and `Hash`.

`Array` is just a list of things with an order. Days of the week, jobs in a queue etc.

`Hash` map a key to a value, like a dictionary (you can also call them dictionaries).

You lookup items inside the structure in the same way - `[]`, like a little pidgeon hole.

`Array`s are only looked up by position: `cats[1]` is... "tabby" (array indexes (position) start from 0).

`Hash`es are looked up by key: `hello["fr"]` is "bonjour".

## Databases

If we had to keep a variable for every bit of data, we'd have to do a lot of typing. Facebook has 500,000,000 users - they don't have a variable `user5000000000`.

Instead, we store data via another program called a database. We send data to the database to be stored, and we can retrieve it later, even in a later run of our program.

## Mongo

We'll be using a very simple database called Mongo. Actually I've made a fake version of it so you don't need to install it, but it looks the same in the code so you'll be able to use Mongo yourself later!

## Database example

So, let's say we just received this URL from the server. We'll be using a framework called sinatra, so let's see how it puts it into data structures for us.

Bob's browser sends us

		GET /?name=bob HTTP/1.1

in our program, we look up

    name = params["name"]
		
		db = FakeMongo::Connection.new
		users = db["users"]

		user = users.find({ "_id" => name })

		respond("<h1>Hello #{user["name"]}, you like #{user["interests"]}</h1>")


## Getting data in

Let's have a sneak preview of the web app we'll be creating:

		user = users.insert("_id" => params["name"], "name" => params["name"])

Pretty simple hey? We're using the name as an id, and also storing it as `name` for consistency.

Updating is also very simple:

		users.update({"_id" => params["name"]},{"visits" => user["visits"] + 1})

## Database summary

We're using a fake version of a database called Mongo. It's free to download

We use databases to store data permantently, so we can retrieve it in our programs.

We `insert` data into the database, `find` it, and we can also `update` it.

## Our first web application

Well done so far...

## Meet Sinatra

Sinatra is an open-source program for writing web applications. It looks like this

		get "/" do
			return "<h1>You just asked for the root path!</h1>"
		end

Nice! So it has a function for the HTTP verb 'get', which takes a route - `"/"`, and we write what looks like a function (it's actually a block - another time) to tell it what to do in response. If we return HTML, it is sent to the client.


