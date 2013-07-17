require "rubygems"
require "sinatra"

enable(:sessions)

# helper functions


# feature request:
# each time a user creates a session
# store how many pages they've viewed this session
	# by increasing a count for every request

def login_signup_form(action)
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

def login user
	session["user_id"] = user["_id"]
	session["page_count"] = 1
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


def record_visit
	if logged_in?
		session["page_count"] = session["page_count"] + 1
	end
end
def number_of_pages_visited
	session["page_count"]
end

# our routes and handlers

get("/") do
  record_visit()
  if logged_in?
		layout <<-HTML
			<h1>Hi #{current_user()}, you've visited #{number_of_pages_visited} pages this session</h1>
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
			#{login_signup_form("/users")}
		HTML
	end
end

get("/login") do
  layout <<-HTML
    <h1>Signup</h1>
    #{login_signup_form("/sessions")}
  HTML
end

post "/sessions" do
  login({"_id" => params["name"]})
  redirect("/")
end

post "/users" do
  user = {"_id" => params["name"]}
  login(user)
  redirect("/")
end

post "/sessions/delete" do
	logout()
	redirect("/")
end
