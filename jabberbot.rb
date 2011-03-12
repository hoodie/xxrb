#!/usr/bin/ruby

require 'xxrb'
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


	# Original greeting function
	xmpp_hello = RbCmd.new(:hello, :xmpp)
	def xmpp_hello.action
		if @args
			result = "I'm not actually " + @args + " but his evil twin"
		else
			result = "hello yourself"
		end
	end
	def xmpp_hello.help
		result = '"hello" is only the first of many cool features'
	end

	# lists all upcomming traffic for a given tram or bus station in Dresden
	# TODO: add command to return list of all stations
	xmpp_dvb = RbCmd.new(:dvb, :xmpp)
	def xmpp_dvb.action
		if @args
			url = URI.parse("http://widgets.vvo-online.de/abfahrtsmonitor/Abfahrten.do?ort=Dresden&hst="+ URI.escape(@args) +"&vz=0")
			#url = URI.parse("http://hoodie.de/logger.php?log=show")
			result = Net::HTTP.start(url.host, url.port) { |http|
				http.get(url.path + "?" + url.query,{'User-Agent' => 'not empty'})
			}
			parsed = JSON::parse(result.body)
			list = parsed.map do |line|
				out = "" unless out
				out += line[2] +"\t"+  line[0] +"\t"+ line[1] + "\n"
			end
			result = "Results for "+@args+":\n" + list.to_s
		else
			result = help
		end
	end
	def xmpp_dvb.help
		result = "dvb - lists all upcomming traffic for a given tram or bus station in Dresden\n example \"dvb slub\" "
	end
 
	# sets the status of the bot
	# TODO: help and args  (online, offline, dnd and so on)
	cli_status = RbCmd.new(:status, :cli)
	def cli_status.action
		@bot.status(@args)
	end


	cli_roster = RbCmd.new(:roster, :cli)
	def cli_roster.action
		@bot.get_roster
	end


# Initialize the bot

bot = Xxrb.new

	# Here we add our commands to the bot
	# Some will later be moved into the Xxrb class and become basic functionality

	bot.add_cmd(cli_help)
	bot.add_cmd(cli_hello)
	bot.add_cmd(cli_connect)
	bot.add_cmd(cli_listen)
	bot.add_cmd(cli_status)
	bot.add_cmd(cli_roster)

	bot.add_cmd(xmpp_hello)
	bot.add_cmd(xmpp_help)
	bot.add_cmd(xmpp_dvb)

	bot.start_cli

