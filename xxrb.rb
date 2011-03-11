
require 'net/http'
require 'uri'
require 'xmpp4r/client'
require 'json/pure'
require 'rbcmd'
include Jabber


#inspired by xmpp4r example client
class Xxrb

	def initialize
		@cli_cmds  = {}
		@xmpp_cmds = {}
	end

	def add_cmd(cmd)
		if cmd.name == "name"
			puts 'can\'t overwrite "exit"'
		elsif cmd.type == :cli
			cmd.set_bot(self)
			@cli_cmds[cmd.name] = cmd
		elsif cmd.type == :xmpp
			cmd.set_bot(self)
			@xmpp_cmds[cmd.name] = cmd
		else
			puts "Couldn't add "+cmd.name
		end
	end

	def hello
		result = "Hello, I am a Jabber Bot. "
		@cmds = "I offer the following functionality:\nquit"
		@cli_cmds.keys.each do |cmd|
			@cmds += ', ' + cmd.to_s 
		end
		result += @cmds
	end
	
	def start_cli
		puts hello
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

	def connect(jid, password)
		@jid, @password = JID.new(jid), password
		@jid.resource=("xxrb") unless @jid.resource
		@client = Client.new(@jid)
		@client.connect
		@client.auth(@password)
	end

	def presence_online(message = nil)
		presence = Presence.new
		presence.set_status(message) if message
		@client.send(presence)
	end


end

