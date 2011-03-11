#!/usr/bin/ruby

require 'net/http'
require 'uri'
require 'xmpp4r/client'
require 'json/pure'
require 'rbcmd'
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

			command, args = line.split(' ', 2)

			unless @cli_cmds[command.to_sym] == nil
				action = lambda { puts @cli_cmds[command.to_sym].execute(args) }
			else
				action = lambda { puts ' > command "'+command+'" not found' }
			end

			unless quit
				action.call end
		end
	end

end


do_help = RbCmd.new(:help, :cli)
def do_help.action
	if @args == "me"
		result = "May I be of some assistence?"
	else
		result = "This is meant to help you"
	end
end

bot = JabberBot.new
bot.add_cmd(do_help)
bot.start_cli
