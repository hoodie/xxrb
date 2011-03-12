# an RbCmd always has a name symbol and a type symbol
# the :name will be the command that will be called later
# the :type can be either :cli or :xmpp which decides from
# where the command will be called 
# you must always overwrite the .action method
# args will be provided within @args
# the bot will be provided within @bot

class RbCmd

	def initialize(n, t = :cli)
		@name = n
		@type = t
	end

	def set_bot(bot)
		@bot = bot
	end

	def bot
		result = @bot
	end

	def execute(args)
		@args = args
		result = action
	end

	def action
		result = "no action set yet"
	end

	def help
		result = @name.to_s + " has no help yet"
	end

	def type
		result = @type
	end

	def name
		result = @name
	end
end


