require "yaml/store"
$db = YAML::Store.new "my_site.store"
require "securerandom"

def find_by_name name
	$db.transaction() do
		$db['users'] ||= {}
    $db['users'][name]
	end
end
alias :find_user :find_by_name
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
    "author_name" => user["name"],
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

