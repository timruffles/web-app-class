require "rubygems"
require "sinatra"


# helper functions

def login_signup_form action
end

def layout(content)
  <<-HTML
    <title>Our first web application</title>
    <link rel=stylesheet href="/stylesheets/foundation.css" />
    <link rel=stylesheet href="/stylesheets/app.css" />
    <body>
      #{content}
    </body>
   HTML
end

# our routes and handlers

get "/" do
  layout <<-HTML
    <h1>Welcome to my fantastic web app</h1>
    <p>It doesn't do a lot, but it does that well.</p>
    <h2>Login</h2>
    #{login_signup_form("/users")}
  HTML
end

get "/login" do
  layout <<-HTML
    <h1>Signup</h1>
    #{login_signup_form("/sessions")}
  HTML
end

post "/sessions" do
  "hello #{params["name"]}"
end

post "/users" do
  "hello #{params["name"]}"
end
