# pull in framework
require "rubygems"
require "sinatra"

# our routes and handlers

get "/" do
  <<-HTML
    <title>Our first web application</title>
    <link rel=stylesheet href="/stylesheets/foundation.css" />
    <link rel=stylesheet href="/stylesheets/app.css" />
    <body>
      <h1>Welcome to my fantastic web app</h1>
      <p>It doesn't do a lot, but it does that well.</p>
      <h2>Signup</h2>
      <form action='/users' method=post>
        <label>
          Name
          <input type=text name=name />
        </label>
        <input type=submit />
      </form>
    </body>
  HTML
end

get "/login" do
  <<-HTML
    <title>Our first web application</title>
    <link rel=stylesheet href="/stylesheets/foundation.css" />
    <link rel=stylesheet href="/stylesheets/app.css" />
    <body>
      <h1>Login</h1>
      <form action='/sessions' method=post>
        <label>
          Name
          <input type=text name=name />
        </label>
        <input type=submit />
      </form>
    </body>
  HTML
end
