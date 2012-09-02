require "rubygems"
require "sinatra"

# configure sinatra
enable "sessions"

# helper functions

def logged_in?
	session["user"] != nil
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
	output = ""
	for key in ["message","woops"] do
		val = session.delete(key)
		if val == nil
			output += ""
		else
			output += <<-HTML
				<p class="#{key}">#{val}</p>
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
	session["user"] = user
end
def logout
	session.delete("user")
end
def current_user
	session["user"]
end
def message msg
	session["message"] = msg
end
def woops msg
	session["woops"] = msg
end

# our fake db connection

require "fake_mongo"

connection = FakeMongo::Connection.new
users = connection['users']

# our routes and handlers

get "/" do
	if logged_in?
		<<-HTML
			<h1>Hi #{current_user()["name"]}</h1>
			<form action="/sessions" method="post">
				<input type=submit value="Logout" />
				<input type=hidden name=_method value=delete />
			</form>
		HTML
	else
		<<-HTML
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
		<<-HTML
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
	<<-HTML
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
		woops("Woops, either your username or password was wrong, or you haven't <a href='/'>signed up</a> yet.")
		redirect('/login', 403)
	end
end

post "/users" do
	if valid_signup?(params["name"])
	  user = users.find({"_id" => params["name"]})
		if not user
			user = users.insert("_id" => params["name"], "name" => params["name"])
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


# admin

get "/admin" do
	user_list = ""
	all_users = users.find.to_a
	for user in all_users
		user_list += "<li>#{user["name"]}"
	end
	if user_list == ""
		user_list = "No users yet, get marketing!"
	end
	<<-HTML
		<h1>Users</h1>
		<ul>
			#{user_list}
		</ul>
	HTML
end
