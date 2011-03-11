#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'xmpp4r/client'
require 'json/pure'
require 'rubotcmd'
include Jabber


#inspired by xmpp4r example client
class JabberBot

	def initialize
		@cli_cmds  = {}
		@xmpp_cmds = {} 
		
	end

	def add_cmd(cmd)
		if cmd.name == "name"
			puts 'can\'t overwrite "exit"'
		elsif cmd.type == :cli
			@cli_cmds[cmd.name] = cmd
		elsif cmd.type == :xmpp
			@xmpp_cmds[cmd.name] = cmd
		else
			puts "Couldn't add "+cmd.name
		end
	end

	def start_cli
		quit = false
		while not quit
			line = gets.strip!
			quit = true if line == 'quit'

			unless @cli_cmds[line.to_sym] == nil
				action = lambda { puts @cli_cmds[line.to_sym].action }
			else
				action = lambda { puts "nothing found" }
			end

			unless quit
				action.call end
		end
	end

end


do_help = RbCommand.new(:help, :cli)
def do_help.action
	result = "May I be of some assistence?"

end

bot = JabberBot.new
bot.add_cmd(do_help)
bot.start_cli
