require "rubygems"
require "sinatra"

# configure sinatra
enable "sessions"

require "yaml/store"

$db = YAML::Store.new "my_site.store"


# View helper functions
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
def layout(content)
  <<-HTML
    <title>Blatherer</title>
    <link rel=stylesheet href="/stylesheets/foundation.css" />
    <link rel=stylesheet href="/stylesheets/app.css" />
    <body>
      #{content}
    </body>
   HTML
end
def blather_stream_html blathers
  blather_html = ""
  for blather in blathers
    blather_html += """
      <li class='blather'>
        <span class='time'>#{blather_time_format(blather["created_at"])}</span>
        <a href='/users/#{blather["user_id"]}' class='author'>#{blather["user_id"]}</a>
        <span class='text'>#{blather_text_to_html(blather["text"])}</span>
      </li>
    """
  end
  blather_html
end
def blather_time_format time
  time.strftime("%P")
end
def blather_text_to_html text
  mentions = get_mentions(text)
  for mention in mentions
    text.gsub!("@#{mention}","<a href='/users/#{mention}'>@#{mention}</a>")
  end
  text
end
def home_link()
  if logged_in?()
    "<a href='/'>Home</a>"
  else
    ""
  end
end

# messaging
def message(msg)
	session["message"] = msg
end
def woops(msg)
	session["woops"] = msg
end

# validations
def valid_signup? name
  name.length > 0 && name.length < 30
end
def valid_blather? text
  text.length > 0 && text.length <= 141
end

# logic
def get_mentions text
  # remove commas etc so @foo, won't be a mention for 'foo,'
  text = text.gsub(",","").gsub("(","").gsub(")","").gsub("-","")
  words = text.split(" ")
  mentions = []
  for word in words
    if word[0] == "@"
      mentions.push(word.slice(1..-1))
    end
  end
  mentions.uniq()
end


# database
require "securerandom"
def all_users
	$db.transaction(true) do
		$db['users'] or {}
	end
end
def find_user id
  all_users().fetch(id)
end
def find_blather id
	$db.transaction() do
		$db["blathers"] ||= {}
    $db["blathers"].fetch(id)
  end
end
def get_user_id user
  user["name"]
end
def create_user user
	$db.transaction() do
    $db["users"] ||= {}
		$db["users"][params["name"]] = user
	end
end
def create_blather text, user
  new_blather = {
    "text" => text,
    "created_at" => Time.now,
    "_id" => SecureRandom.uuid,
    "mentions" => get_mentions(text),
    "user_id" => get_user_id(user)
  }
	$db.transaction() do
		$db["blathers"] ||= {}
    $db["blathers"][new_blather["_id"]] = new_blather
	end
end
def find_user_blathers user
	$db.transaction() do
    blathers = []
		for id, blather in $db["blathers"]
      if blather["user_id"] == get_user_id(user)
        blathers.push(blather)
      end
    end
    blathers.reverse()
	end
end
def find_mentions_for user
	$db.transaction() do
    blathers = []
		for id, blather in $db["blathers"]
      if blather["mentions"].include?(get_user_id(user))
        blathers.push(blather)
      end
    end
    blathers
	end
end
def find_user_home_stream user
  whole_stream = find_mentions_for(user) + find_user_blathers(user)
  whole_stream = whole_stream.sort_by do |blather|
    blather["created_at"]
  end
  whole_stream = whole_stream.uniq() do |blather|
    blather["_id"]
  end
  whole_stream.reverse().slice(0..9)
end

# authentication
def logged_in?
	current_user() != nil
end
def login user
	session["user_id"] = user["name"]
end
def logout
	session.delete("user_id")
end
def current_user
	if session["user_id"]
		user = all_users[session["user_id"]]
		if user == nil
			session.delete("user_id")
		end
		user
	else
		nil
	end
end



# our routes and handlers

get("/") do
	if logged_in?()
    blather_html = blather_stream_html(find_user_home_stream(current_user()))
		layout <<-HTML
			<h1>Hi #{current_user()["name"]}</h1>
			#{info_boxes()}
      <a href="/blather">Do you have something you need to blather about?</a>
			<form action="/sessions" method="post">
				<input type=submit value="Logout" />
				<input type=hidden name=_method value=delete />
			</form>
      <h2>Timeline</h2>
      <ul>
        #{blather_html}
      </ul>
		HTML
	else
		layout(<<-HTML
			<h1>Welcome to my fantastic web app</h1>
			#{info_boxes()}
			<p>It doesn't do a lot, but it does that well. Look at all our our <a href="/users">users</a>.</p>
			<h2>Signup</h2>
			#{login_signup_form("/users")}
		HTML
    )
	end
end

get("/signup") do
	if logged_in?()
		redirect("/")
	else
		layout( <<-HTML
			<h1>Signup</h1>
			#{info_boxes()}
			#{login_signup_form("/users")}
		HTML
    )
	end
end

post("/users") do
	if valid_signup?(params["name"])
	  user = all_users()[params["name"]]
		if not user
			user = { "name" => params["name"], "created_at" => Time.now }
      create_user(user)
      message("Let's get blathering!")
		else
			message("You're already signed up, so we logged you in.")
		end
		login(user)
		redirect("/blather")
	else
		woops("Sorry, your name needs to be 2-60 letters or spaces.")
		redirect('/signup')
	end
end

get("/login") do
	if logged_in?()
		return redirect("/")
	end
	layout( <<-HTML
		<h1>Login</h1>
		#{info_boxes()}
		#{login_signup_form("/sessions")}
	HTML
  )
end

post("/sessions") do
	if user = all_users[params["name"]]
		login(user)
		redirect("/")
	else
		woops("Woops, either your username or password was wrong, or you haven't <a href='/signup'>signed up</a> yet.")
		redirect('/login')
	end
end

delete("/sessions") do
	logout()
	message("See you next time!")
	redirect("/")
end


get("/users/:id") do
  
  user = find_user(params["id"])
  if !user
    raise Sinatra::NotFound.new
  end
  blathers = find_user_blathers(user)
  
  if blathers.length == 0
    blather_html = "#{user["name"]} hasn't been blathering yet. Perhaps you should provoke them into it?"
  else
    blather_html = blather_stream_html(blathers)
  end
  
  layout( <<-HTML
    #{home_link()}
    <h2>#{user["name"]}'s blatherings</h2>
    <ul class="blathers">
      #{blather_html}
    </ul>
  HTML
  )

end

get("/blather") do
  layout( <<-HTML
    <form action="/blather" method="post">
      <label>What are you blathering about?</label>
      <input type="text" name="text" maxlength="141" autofocus />
      <button>Blather</button>
    </form>
  HTML
  )
end

post("/blather") do
  text = params.fetch("text")
  if valid_blather?(text)
    create_blather(text, current_user())
    message("What fascinating blathering!")
    redirect("/")
  else
    woops("Sorry, that's not a valid blather!")
    redirect("/blather")
  end
end

