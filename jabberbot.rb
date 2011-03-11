#!/usr/bin/ruby

require 'xxrb'

bot = Xxrb.new

# Here we start defining new commands

	cli_help = RbCmd.new(:help, :cli)
	def cli_help.action
		if @args == "me"
			result = "May I be of some assistence?"
		else
			result = "This is meant to help you"
		end
	end

	cli_hello = RbCmd.new(:hello, :cli)
	def cli_hello.action
		@bot.hello
	end

	cli_connect = RbCmd.new(:connect, :cli)
	def cli_connect.action
		j,p = @args.split(' ',2)
		@bot.connect(j,p) if @args 
		@bot.presence_online("I'm on and off for testing")
		result = " > now we should be connected"
	end

	cli_listen = RbCmd.new(:listen, :cli)
	def cli_listen.action
		result = @bot.start_xmpp_interface
	end
 


# Here we add our commands to the bot
# Some will later be moved into the Xxrb class and become basic functionality

	bot.add_cmd(cli_help)
	bot.add_cmd(cli_hello)
	bot.add_cmd(cli_connect)
	bot.add_cmd(cli_listen)


bot.start_cli
