#!/usr/bin/ruby

# This Class initializes the bot which is defined in xxrb.rb
# it defines commands that make use of core functionality within xxrb
# and adds them to the bot.
# This way the bot can be extended with new functionality that is not
# neccessarily xmpp related.
# For example you could add a command named 'calc' that parses a mathmatic
# calculation and returnes the result.
# The bot than will accept the command via xmpp and send back a response
# the same way (normal or chat)

require 'xxrb'
require 'yaml'
require 'json/pure'
require 'net/http'
require 'uri'



# Here we start defining new commands

	cli_help = RbCmd.new(:help, :cli)
	def cli_help.action
		if @args.nil?
			result = @bot.cmds(@bot.cli_cmds)
		else
			unless @bot.cli_cmds[@args.to_sym] == nil
				result = @bot.cli_cmds[@args.to_sym].help
			else
				result = "There is no such command"
			end
		end
	end


	# Repeats welcoming message
	cli_hello = RbCmd.new(:hello, :cli)
	def cli_hello.action
		@bot.hello
	end

	# Offers Manual connecting
	# "connect [user@server/resource password]"
	cli_connect = RbCmd.new(:connect, :cli)
	def cli_connect.action
		result = if @args
			j,p = @args.split(' ',2)
			result = @bot.connect(j,p)
		else
			result = @bot.connect
		end
		result += "\n" + @bot.status("I'm on and off for testing")
		result += "\n" + @bot.start_xmpp_interface
	end


	# Starts listening to xmpp input
	cli_listen = RbCmd.new(:listen, :cli)
	def cli_listen.action
		result = @bot.start_xmpp_interface
	end


	# Help for XMPP Commands
	xmpp_help = RbCmd.new(:help, :xmpp)
	def xmpp_help.action
		if @args.nil?
			result = @bot.cmds(@bot.xmpp_cmds)
		else
			unless @bot.xmpp_cmds[@args.to_sym] == nil
				result = @bot.xmpp_cmds[@args.to_sym].help
			else
				result = "There is no such command"
			end
		end
	end


 
	# sets the status of the bot
	# TODO: help and args  (online, offline, dnd and so on)
	cli_status = RbCmd.new(:status, :cli)
	def cli_status.action
		@bot.status(@args)
	end


	# List roster items
	cli_roster = RbCmd.new(:roster, :cli)
	def cli_roster.action
		@bot.roster
	end
	def cli_roster.help
		'lists all contacts on the roster'
	end

	# send a 'chat' message to jid
	cli_chat= RbCmd.new(:chat, :cli)
	def cli_chat.action
		if @bot.connected
			if(@args)
				@bot.send(:chat, @args)
			else
				" > no recipient"
			end
		else
			'not connected'
		end
	end
	def cli_chat.help
		'Usage: "chat jid" the next line will be sent'
	end

	# send a 'normal' message to jid
	cli_send = RbCmd.new(:send, :cli)
	def cli_send.action
		if @bot.connected
			if(@args)
				@bot.send(:normal, @args)
			else
				" > no recipient"
			end
		else
			'not connected'
		end
	end
	def cli_send.help
		'Usage: "send jid" the next line will be sent'
	end

	cli_remove = RbCmd.new(:remove, :cli)
	def cli_remove.action
		@bot.unsubscribe(@args)
	end
  
	cli_whoami= RbCmd.new(:whoami, :cli)
	def cli_whoami.action
		@jid
	end
	

# Initialize the bot

bot = Xxrb.new

	# Here we add our commands to the bot
	# Some will later be moved into the Xxrb class and become basic functionality


	#bot.fallback = lambda { |command, args| puts command }

	bot.add_cmd(cli_help)
	bot.add_cmd(cli_send)
	bot.add_cmd(cli_chat)
	bot.add_cmd(cli_whoami)
	bot.add_cmd(cli_connect)
	#bot.add_cmd(cli_listen)
	bot.add_cmd(cli_status)
	bot.add_cmd(cli_roster)


	bot.add_cmd(xmpp_help)

	bot.start_cli

