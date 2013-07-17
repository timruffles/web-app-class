
def while_loop()
	number = 0
	while(number < 10) do
		number += 1
		puts number
	end
end

def with_an_array()
	[1,2,3,4,5,6,7,8,9,10].each { |number| puts number }
end

def with_a_number()
	10.times do |nth_time|
		puts nth_time + 1
	end
end

def with_a_range()
	("a".."z").each do |number|
	end
end

def every_odd_number_while(start,finish)
	current = start
	while(current <= finish) do
		if current.even?
			puts current
		end
		current += 1
	end
end

def every_odd_number_while(start,finish)
	(start..finish).each do |current|
		if current.even?
			puts current 
		end
	end
end

def every_odd_number_enumerator(start,finish)
	(start..finish).select(&:even?).each do |even_number|
		puts even_number
	end
end


def main()
	puts "with a loop:"
	while_loop()
	puts "with an array:"
	with_an_array()
	puts "with a number:"
	with_a_number()
	puts "with a range:"
	with_a_range()
end

def filtering()
	every_odd_number_while(1,10)
	every_odd_number_enumerator(1,10)
end

filtering()