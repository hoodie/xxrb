#!/usr/bin/ruby

require 'xxrb'

bot = Xxrb.new

# Here we start defining new commands

	do_help = RbCmd.new(:help, :cli)
	def do_help.action
		if @args == "me"
			result = "May I be of some assistence?"
		else
			result = "This is meant to help you"
		end
	end

	do_hello = RbCmd.new(:hello, :cli)
	def do_hello.action
		@bot.hello
	end



# Here we add our commands to the bot
# Some will later be moved into the Xxrb class and become basic functionality

	bot.add_cmd(do_help)
	bot.add_cmd(do_hello)

bot.start_cli
