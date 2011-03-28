
require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'
require 'yaml'
require 'rbcmd'
require 'xep49-storer'
include Jabber


class Xxrb

	attr :cli_fallback, :xmpp_fallback
	attr_reader :connected, :cli_cmds, :xmpp_cmds, :storer, :client

	def initialize
		@cli_cmds  = {}
		@xmpp_cmds = {}
		@connected = false

		#@storer = XEP49.new(self)

		if File.exists?('config.yml')
			file = File.open('config.yml')
			@config = YAML::load(file)
			file.close

			@jid = @config['account']['jid']
			@password = @config['account']['password']
			@autoauthorize = @config['options']['autoauthorize']

			@cli_fallback = lambda { |command, args, jid|  command + ' is not a command'  }
			@xmpp_fallback = lambda { |command, args, jid| command + ' is not a command'  }

		else
			puts "Error: no config file"
			Thread.current.exit
		end
		
		if @config['options']['autologin']
			puts connect(@jid,@password)
			puts status(@config['defaults']['status'])
			puts start_xmpp_interface
			puts "\n"
		end
	end

	# Begin of getters
	def roster
		get_roster
		@roster_string
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
	def take_cmd(pool, line, jid = nil)
		command, args = line.split(' ', 2) unless line.nil? 
		if command	
			unless pool[command.to_sym] == nil
				action = lambda { pool[command.to_sym].execute(args, jid) }
			else
				if pool == @cli_cmds
					action = lambda{ @cli_fallback.call(command, args, jid) }
				else
					action = lambda{ @xmpp_fallback.call(command, args, jid) }
				end
			end
		else
			action = proc {}
		end
		action
	end


	
	# Begin responding to commandline input
	def start_cli
		puts hello
		quit = false
		while not quit
			line = gets.strip!

			quit = true if line == 'quit'
			action = take_cmd(@cli_cmds, line, @jid)
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
					puts message.from.to_s + ": \""+message.body.strip+"\""
					action = take_cmd(@xmpp_cmds, message.body.strip, message.from)
					output = action.call.to_s
					res = Message.new(message.from, output)
					res.type = message.type
					@client.send(res)
				end
			}
			@client.add_iq_callback(0,'puts') { |iq| iq_dispatch(iq) }
			result = " > listening for commands from xmpp"
		else
			result = " > not yet connected, please connect first"
		end
	end

	def iq_dispatch(iq)
		#iq.root.elements.each('//user') { |e| e.to_s }
		puts ">>> " + iq.to_s
	end



	# Begin of XMPP Functions


	# Connect either to given jid or to jid from config
	def connect(jid = nil, password = nil)
		unless jid.nil? or password.nil?
			@jid, @password = JID.new(jid), password
			@jid.resource=(@config['defaults']['resource']) unless @jid.resource
			@client = Client.new(@jid)
			@client.connect
			@client.auth(@password)

			init_roster
			get_roster
			accept_subscribers
			@connected = true
			result = " > connected to "+ @jid.domain
		else
			connect(@jid, @password)
		end
	end

	def exec(stanza)
		if @connected
			@client.send(stanza)
		else
			puts "not connected"
		end
	end


	def accept_subscribers
		@roster.add_subscription_request_callback do |item, presence|
			if @autoauthorize
				@roster.accept_subscription(presence.from)
				@roster.add(presence.from,presence.from.node.to_s, true) #TODO add() untested
			else
				puts '!!! accept ' + presence.from.to_s + '? (yes/No)'
				if gets.strip.downcase == 'yes'
					@roster.accept_subscription(presence.from)
					@roster.add(presence.from,presence.from.node.to_s, true)
				else
					@roster.decline_subscription(presence.from)
				end
			end
		end
	end


	
	# sends a message to a recipient either as type (:chat, :groupchat, :headline, :normal )
	def send(type, recipient)
		body = gets.strip
		message = Message.new(JID.new(recipient),body)
		message.type=(type)
		@client.send(message)
	end



	# initializes roster
	def init_roster
		if @client
			@roster = Jabber::Roster::Helper.new(@client)
#			rosterthread = Thread.current
#			@roster.add_query_callback do |iq|
#				rosterthread.wakeup
#			end
#			Thread.stop
		end
	end


	# lists roster
	def get_roster
		if @roster
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


	# removes jid subscription
	def unsubscribe(jid)
		jid = JID.new(jid.strip)

		deletees = @roster.find(jid)
		if deletees.count == 1
			if deletees[jid.strip].remove
				puts "removed " + jid.strip
			end
		else
			puts jid.to_s + ' not found'
		end
	end


	


end
