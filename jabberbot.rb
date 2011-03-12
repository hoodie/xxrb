#!/usr/bin/ruby

require 'xxrb'
require 'yaml'

bot = Xxrb.new

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

	cli_hello = RbCmd.new(:hello, :cli)
	def cli_hello.action
		@bot.hello
	end

	cli_connect = RbCmd.new(:connect, :cli)
	def cli_connect.action
		j,p = @args.split(' ',2)
		@bot.connect(j,p) if @args 
		@bot.presence_online("I'm on and off for testing")
		result = "> now we should be connected"
		result += "\n" + @bot.start_xmpp_interface
	end

	cli_listen = RbCmd.new(:listen, :cli)
	def cli_listen.action
		result = @bot.start_xmpp_interface
	end

	cli_quickconnect = RbCmd.new(:quick, :cli)
	def cli_quickconnect.action
		file = File.open('login')
		login = YAML::load(file)
		file.close
		@bot.connect(login['jid'],login['password'])
		@bot.presence_online("I'm on and off for testing")
		result = login['jid']
	end

	xmpp_help = RbCmd.new(:help, :xmpp)
	def cli_help.action
		if @args.nil?
			result = @bot.cmds(@bot.cli_cmds)
		else
			unless @bot.xmpp_cmds[@args.to_sym] == nil
				result = @bot.xmpp_cmds[@args.to_sym].help
			else
				result = "There is no such command"
			end
		end
	end

	xmpp_hello = RbCmd.new(:hello, :xmpp)
	def xmpp_hello.action
		result = "I'm not actually " + @args + " but his evil twin"
	end
	def xmpp_hello.help
		result = '"hello" is only the first of many cool features'
	end
 


# Here we add our commands to the bot
# Some will later be moved into the Xxrb class and become basic functionality

	bot.add_cmd(cli_help)
	bot.add_cmd(cli_hello)
	bot.add_cmd(cli_connect)
	bot.add_cmd(cli_quickconnect)
	bot.add_cmd(cli_listen)

	bot.add_cmd(xmpp_hello)
	bot.add_cmd(xmpp_help)


bot.start_cli
