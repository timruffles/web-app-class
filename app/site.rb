require "rubygems"
require "sinatra"

# configure sinatra
enable "sessions"

# our fake db connection

require "fake_mongo"
$connection = FakeMongo::Connection.new


# helper functions

def logged_in?
	current_user != nil
end
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
def info_boxes
  class_name = { "message" => "", "woops" => "alert" }
	output = ""
	for key in ["message","woops"] do
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
def valid_signup? name
	name_pattern = / 
		\A         		# start of string
		[a-z]				  # starts with a letter
		[a-z ]{0,60}  # then 0-60 letters or spaces
		[a-z]         # finishes with a letter ( so in all, shortest possible name is two letters )
		\Z       	    # end of string
	/xi 
	name_pattern =~ name
end
def login user
	session["user_id"] = user["_id"]
end
def logout
	session.delete("user_id")
end
def current_user
	if session["user_id"]
		user = users.find({"_id" => session["user_id"]})
		if user == nil
			session.delete("user_id")
		end
		user
	else
		nil
	end
end
def message(msg)
	session["message"] = msg
end
def woops(msg)
	session["woops"] = msg
end
def users
	$connection['users']
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
	if logged_in?
		layout <<-HTML
			<h1>Hi #{current_user()["name"]}</h1>
			#{info_boxes()}
			<form action="/sessions" method="post">
				<input type=submit value="Logout" />
				<input type=hidden name=_method value=delete />
			</form>
		HTML
	else
		layout <<-HTML
			<h1>Welcome to my fantastic web app</h1>
			#{info_boxes()}
			<p>It doesn't do a lot, but it does that well.</p>
			<h2>Signup</h2>
			#{login_signup_form("/users")}
		HTML
	end
end

get "/signup" do
	if logged_in?()
		redirect("/")
	else
		layout <<-HTML
			<h1>Signup</h1>
			#{info_boxes()}
			#{login_signup_form("/users")}
		HTML
	end
end

get "/login" do
	if logged_in?()
		return redirect("/")
	end
	layout <<-HTML
		<h1>Login</h1>
		#{info_boxes()}
		#{login_signup_form("/sessions")}
	HTML
end

post "/sessions" do
	if user = users.find({ "_id" => params["name"] })
		login(user)
		redirect("/")
	else
		woops("Woops, either your username or password was wrong, or you haven't <a href='/signup'>signed up</a> yet.")
		redirect('/login')
	end
end

post "/users" do
	if valid_signup?(params["name"])
	  user = users.find({"_id" => params["name"]})
		if not user
			user = users.insert("_id" => params["name"], "name" => params["name"])
		else
			message("You're already signed up, so we logged you in.")
		end
		login(user)
		redirect("/")
	else
		woops("Sorry, your name needs to be 2-60 letters or spaces.")
		redirect('/signup')
	end
end

delete "/sessions" do
	logout()
	message("See you next time!")
	redirect("/")
end

get "/our-users" do
	user_list = ""
	all_users = users.find.to_a
	for user in all_users
		user_list += "<li>#{user["name"]}"
	end
	if user_list == ""
		user_list = "No users yet, <a href=/signup>be the first</a>!"
	end
	layout <<-HTML
		<h1>Our users</h1>
		<ul>
			#{user_list}
		</ul>
	HTML
end
