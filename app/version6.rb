require "rubygems"
require "sinatra"

enable :sessions
set :session_secret, 'really secret'

# helper functions

def login_signup_form action
	<<-HTML
		<form action='#{action}' method=post>
			<label>
				Name
				<input type=text name=name />
			</label>
			<input type=submit />
		</form>
	HTML
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

def valid_signup? name
  name.length > 1 && name.length < 30
end
def message(msg)
	session["message"] = msg
end
def woops(msg)
	session["woops"] = msg
end
def info_boxes
    class_name = { "message" => "", "woops" => "alert" }
	["message","woops"].each do |key|
		val = session.delete(key)
		if val == nil
			output += ""
		else
			output += <<-HTML
				<p class="alert-box #{class_name[key]}">#{val}</p>
			HTML
		end
	end
	output
end

def login user
	session["user_id"] = user["_id"]
end
def current_user
	session["user_id"]
end
def logged_in?
	current_user != nil
end
def logout
	session.delete("user_id")
end

# our routes and handlers

get "/" do
  if logged_in?
		layout <<-HTML
			<h1>Hi #{current_user()}</h1>
			<form action="/sessions" method="post">
				<input type=submit value="Logout" />
				<input type=hidden name=_method value=delete />
			</form>
		HTML
	else
		layout <<-HTML
			<h1>Welcome to my fantastic web app</h1>
			<p>It doesn't do a lot, but it does that well.</p>
			<h2>Signup</h2>
      #{info_boxes()}
			#{login_signup_form("/users")}
		HTML
	end
end

get "/login" do
  layout <<-HTML
    <h1>Signup</h1>
    #{login_signup_form("/sessions")}
  HTML
end

post "/sessions" do
  login({"_id" => "you"})
  redirect("/")
end

post "/users" do
	if valid_signup?(params["name"])
    	user = {"_id" => params["name"]}
		login(user)
		redirect("/")
	else
		woops("Sorry, your name needs to be 2-30 letters or spaces.")
		redirect('/')
	end
end

delete "/sessions" do
	logout()
	message("See you next time!")
	redirect("/")
end
