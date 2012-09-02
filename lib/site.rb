# defining record types
User = Struct.new(:name)

# configure sinatra
enable :sessions

# helper functions

def logged_in?
	not session[:user].nil?
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
def message_box
	if session[:message] == nil
		return "" 
	end
	message = session.delete(:message)
	<<-HTML
		<p class="message">#{message}</p>
	HTML
end
def valid_signup name
	/ \A         # start of string
		\w 				 # starts with a letter
		[\w ]{,60} # then 0-60 letters or spaces
		\w         # finishes with a letter ( so in all, shortest possible name is two letters )
		\Z       	 # end of string
	/x =~ name
end

# our fake db connection

require "fake_mongo"

connection = Mongo::Connection.new
users = connection['users']

# our routes and handlers

get "/" do
	if logged_in?
		<<-HTML
			<h1>Hi #{current_user.name}</h1>
		HTML
	else
		<<-HTML
			<h1>Welcome to my fantastic web app</h1>
			<p>It doesn't do a lot, but it does that well.</p>
			<h2>Signup</h2>
			#{login_signup_form("/users")}
		HTML
	end
end

get "/signup" do
	if logged_in?
		redirect(to("/"))
	else
		<<-HTML
			<h1>Signup</h1>
			#{login_signup_form("/users")}
		HTML
	end
end

get "/login" do
	<<-HTML
		<h1>Login</h1>
		#{message_box}
		#{login_signup_form("/sessions")}
	HTML
end

post "/sessions" do
	if user = users.find({ :_id => param[:name] })
		session[:user] = name
	else
		session[:message] = "Woops, either your username or password was wrong, or you haven't <a href='/'>signed up</a> yet."
		redirect(to('/login'), 403)
	end
end

post "/users" do
	if valid_signup?(param[:name])
		users.insert(:_id => params[:name], :name => params[:name])
	else
		redirect(to('/signup'))
	end
end
