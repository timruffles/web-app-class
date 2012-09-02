require "json"

class FakeMongo
	def initialize
		@db = JSON.parse(open("db.fakemongo").read)
	end
	attr_reader :db

	class Connection
		def initialize db
		end
		def collection name
			Collection.new(name,db)
			else
				nil
			end
		end
		alias :collection :[]
	end
	class Collection
		def initialize name, db
			@db = db
			@db[name] ||= Struct.new(
				:pkey => 0,
				:rows => {}
			)
			@coll = @db[name]
		end
		def find query
			id = query.delete(:_id)
			raise "Fake Mongo only supports lookup by id" unless id
			@coll[id]
		end
		def insert params
			if not params[:_id]
				params[:_id] ||= @coll.pkey
				@coll.pkey += 1
			end
			if @coll.rows[params[:_id]]
				raise "E11000 duplicate key error index (Fake Mongo implementation of mongo error)"
			else
				@coll.rows[params[:_id]] = params
			end
		end
		def update query, doc
			raise "cannot change _id of a document" unless doc[:id].nil?
			find(query).merge!(doc)
		end
	end
end


