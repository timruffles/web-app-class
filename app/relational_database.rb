require "pg"
require "uri"

string = ENV.fetch("DATABASE_URL","postgres://postgres@localhost/my_first_webapp")

uri = URI.parse string
host = uri.host
db = uri.path[1..-1]
port = uri.port
pass = uri.password
user = uri.user

auth = if pass
  {:user => user, :password => pass }
else
  {}
end

$conn = PG.connect({
  :dbname => db,
  :port => port,
  :host => host
}.merge(auth))

# run this function to create the database, or copy and paste into the dbconsole
def create_database
  $conn.exec("""
    CREATE TABLE users (
      id SERIAL NOT NULL,
      name varchar(255) NOT NULL,
      created_at timestamp NOT NULL,
      PRIMARY KEY (id)
    );
    CREATE UNIQUE INDEX user_names ON users (name);
    CREATE TABLE blathers (
      id SERIAL NOT NULL,
      text varchar(141) NOT NULL,
      created_at timestamp NOT NULL,
      user_id integer NOT NULL,
      PRIMARY KEY (id)
    );
    CREATE TABLE blathers_mentioned_users (
      blather_id integer NOT NULL,
      user_id integer NOT NULL,
      PRIMARY KEY (blather_id, user_id)
    );
  """)
end

def find_user id
  $conn.exec_params(
    "SELECT * FROM users WHERE id = $1",
    [id]
  ).first
end
def find_blather id
  $conn.exec_params(
    """SELECT b.*, u.name as author_name
    FROM blathers b
    INNER JOIN users u ON b.user_id = u.id
    WHERE id = $1""",
    [id]
  ).first
end
def get_user_id user
  user["id"]
end
def create_user user
  result = $conn.exec_params(
    "INSERT INTO users (name,created_at) VALUES ($1,$2) RETURNING id",
    [user["name"],user["created_at"]]
  )
  user["id"] = result.first["id"]
end
def find_by_name name
  $conn.exec_params("SELECT * FROM users WHERE name = $1",[name]).first
end
def create_blather text, user
  mentions = get_mentions(text)
  if mentions.length > 0
    escaped_mentions = mentions.map do |mention|
      "'#{$conn.escape_string(mention)}'"
    end.join(",")
    mentioned_users = $conn.exec(
      "SELECT id FROM users WHERE name IN (#{escaped_mentions})"
    ).to_a
  else
    mentioned_users = {}
  end
  $conn.transaction do
    new_blather_id = $conn.exec_params(
      "INSERT INTO blathers (text, created_at, user_id) VALUES ($1,$2,$3) RETURNING id",
      [text,Time.now,get_user_id(user)]
    ).to_a.first
    if mentioned_users.length > 0
      inserts = mentioned_users.map do |user|
        "(#{new_blather_id["id"]},#{user["id"]})"
      end.join(", ")
      $conn.exec("""
        INSERT INTO blathers_mentioned_users (blather_id, user_id)
        VALUES #{inserts}
      """)
    end
  end
end
def get_blather_id blather
  blather["id"]
end
def parse_dates rows
  if rows.empty? || !rows.first.fetch("created_at",false)
    return rows
  end
  rows.each do |row|
    row["created_at"] = Date.parse row.fetch("created_at")
  end
  rows
end
def find_user_blathers user
  parse_dates $conn.exec_params("""
    SELECT b.*, u.name as author_name
    FROM blathers b
    INNER JOIN users u ON b.user_id = u.id
    WHERE user_id = $1 ORDER BY b.created_at DESC""",
    [get_user_id(user)]
  ).to_a
end
def find_mentions_for user
  parse_dates $conn.exec_params("""
    SELECT b.*, u.name as author_name 
    FROM blathers b
    INNER JOIN users u ON b.user_id = u.id 
    WHERE b.id IN (
      SELECT bmu.blather_id FROM blathers_mentioned_users bmu
      WHERE bmu.user_id = $1
    ) ORDER BY b.created_at DESC
  """,[get_user_id(user)]).to_a
end
def find_user_home_stream user
  whole_stream = find_mentions_for(user) + find_user_blathers(user)
  whole_stream = whole_stream.sort_by do |blather|
    blather["created_at"]
  end
  whole_stream = whole_stream.uniq() do |blather|
    get_blather_id(blather)
  end
  whole_stream.reverse().slice(0..9)
end
