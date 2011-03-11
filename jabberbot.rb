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

	do_connect = RbCmd.new(:connect, :cli)
	def do_connect.action
		j,p = @args.split(' ',2)
		@bot.connect(j,p) if @args 
		@bot.presence_online("I'm on and off for testing")
		result = " > now we should be connected"
	end

	do_listen = RbCmd.new(:listen, :cli)
	def do_listen.action
		result = @bot.start_xmpp_interface
	end
 


# Here we add our commands to the bot
# Some will later be moved into the Xxrb class and become basic functionality

	bot.add_cmd(do_help)
	bot.add_cmd(do_hello)
	bot.add_cmd(do_connect)
	bot.add_cmd(do_listen)


bot.start_cli
