require "rubygems"
require "sinatra"

# configure sinatra
enable "sessions"

require "yaml/store"

$db = YAML::Store.new "my_site.store"


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
	session["user_id"] = user["name"]
end
def logout
	session.delete("user_id")
end
require "pp"
def current_user
	if session["user_id"]
		user = users[session["user_id"]]
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
	users = $db.transaction(true) do
		$db['users']
	end
	users or {}
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
			<p>Look at your fellow <a href="/users">users</a>.</p>
			<form action="/sessions" method="post">
				<input type=submit value="Logout" />
				<input type=hidden name=_method value=delete />
			</form>
		HTML
	else
		layout <<-HTML
			<h1>Welcome to my fantastic web app</h1>
			#{info_boxes()}
			<p>It doesn't do a lot, but it does that well. Look at all our our <a href="/users">users</a>.</p>
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
	if user = users[params["name"]]
		login(user)
		redirect("/")
	else
		woops("Woops, either your username or password was wrong, or you haven't <a href='/signup'>signed up</a> yet.")
		redirect('/login')
	end
end

post "/users" do
	if valid_signup?(params["name"])
	  user = users[params["name"]]
		if not user
			user = { "name" => params["name"], "created_at" => Time.now }
			current_users = users
			$db.transaction do
				$db["users"] = current_users.merge({ params["name"] => user })
			end
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

get "/users" do
	user_list = ""
	all_users = users
	for name, user in all_users
		pp name, user
		user_list += "<li>#{user["name"]} - signed up #{user["created_at"].to_s}</li>"
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
