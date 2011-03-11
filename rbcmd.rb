class RbCmd
	def initialize(n, t = :cli)
		@name = n
		@type = t
	end

	def execute(args)
		@args = args
		result = action
	end

	def action
		result = "nothing set yet"
	end

	def type
		result = @type
	end

	def name
		result = @name
	end
end


