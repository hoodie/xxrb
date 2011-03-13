
require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'
require 'yaml'
require 'rbcmd'
include Jabber


#inspired by xmpp4r example client
class Xxrb

	def initialize
		@cli_cmds  = {}
		@xmpp_cmds = {}
		if File.exists?('config.yml')
			file = File.open('config.yml')
			conf = YAML::load(file)
			file.close

			@jid = conf['account']['jid']
			@password = conf['account']['password']

		else
			puts "Error: no config file"
			Thread.current.exit
		end
	end

	# Begin of getters
	def cli_cmds
		@cli_cmds
	end

	def xmpp_cmds
		@xmpp_cmds
	end

	def roster
		@roster_string
	end

	def connected
		@connected || false
	end
	# End of getters


	# Begin of command functions

	# welcoming message for cli users
	def hello
		result = "Hello, I am a Jabber Bot. "
		result += "\n" + cmds(@cli_cmds)
	end


	# register new commands
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


	# List all commands from a given pool
	def cmds(pool)
		cmds = ""
		pool.keys.each do |cmd|
			unless cmds == ""
				cmds += ', ' + cmd.to_s 
			else
				cmds += cmd.to_s 
			end
		end
		cmds += " and quit!" if pool == @cli_cmds
		result = " > Available commands: " + cmds
	end


	# Parse commandline input and deligate to either xmpp_cmds or cli_cmds
	def take_cmd(pool, line)
		command, args = line.split(' ', 2) unless line.nil? 
		if command	
		unless pool[command.to_sym] == nil
			action = lambda { pool[command.to_sym].execute(args) }
		else
			action = proc { 'command "'+command+'" not found' }
		end
		else
			action = proc {}
		end
	end

	
	# Begin responding to commandline input
	def start_cli
		puts hello
		quit = false
		while not quit
			line = gets.strip!

			quit = true if line == 'quit'
			action = take_cmd(@cli_cmds, line)
			unless quit
				output = action.call
				puts output unless output.nil?
			end
		end
	end

	
	# Begin responding to xmpp input
	def start_xmpp_interface
		if @client
			@client.add_message_callback { |message|
				unless message.type == :error
					puts message.from.to_s+": \""+message.body.strip+"\""
					action = take_cmd(@xmpp_cmds, message.body.strip)
					output = action.call.to_s
					res = Message.new(message.from, output)
					res.type = message.type
					@client.send(res)
				end
			}
			@client.add_iq_callback { |iq|
				puts iq
			}
			result = " > listening for commands from xmpp"
		else
			result = " > not yet connected, please connect first"
		end
	end

	# Begin of XMPP Functions

	# Connect either to given jid or to jid from config
	def connect(jid = nil, password = nil)
		unless jid.nil? and password.nil?
			@jid, @password = JID.new(jid), password
			@jid.resource=("xxrb") unless @jid.resource
			@client = Client.new(@jid)
			@client.connect
			@client.auth(@password)

			get_roster
			#accept_subscribers
			@connected = true
		else
			connect(@jid, @password)
		end
		result = " > connected to "+ @jid.domain
	end

	def accept_subscribers
		@client.add_subscription_request_callback do |p|
			puts "!! somebody whats to be our friend"
		end

		lambda do |p|
			if p.type == :subscribed
				puts '! ' + 'somebody whats has subscribed me'
			elsif p.type == :unsubscribe
				puts '! ' + p.from.to_s + " doesn't want to be my friend anymore"
			elsif p.type == :unsubscribed
				puts '! ' + p.from.to_s + " ended this relationship"
			end
		end
	end

	def send(type, recipient)
		body = gets.strip
		message = Message.new(JID.new(recipient),body)
		message.type=(type)
		@client.send(message)
	end

	# lists roster
	def get_roster
		if @client
			@roster = Jabber::Roster::Helper.new(@client)
			rosterthread = Thread.current
			@roster.add_query_callback do |iq|
				rosterthread.wakeup
			end
			Thread.stop
			@roster_string = ""
			@roster.groups.each do |group|
				if group.nil?
					@roster_string += "\n"
				else
					@roster_string += group.to_s + "\n"
				end

				@roster.find_by_group(group).each do |item|
					if item.iname
						@roster_string += "- " + item.iname.to_s + "\n"
					else
						@roster_string += "- " + item.jid.to_s + "\n"
					end
				end
			end
		else
			@roster_string = " > not yet connected"
		end
		@roster_string
	end

	# TODO does not return status correctly
	def status(message = nil)
		if @client and message
			presence = Presence.new
			presence.set_status(message)
			presence.set_show(:chat) 
			@client.send(presence)
			result = " > set status message to \"" + message + "\""
		elsif @client
			result = '"'+ @client.status.to_s + '"'
		else
			result = " > not yet connected"
		end
	end
end

