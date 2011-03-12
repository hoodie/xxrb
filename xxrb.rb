require 'xmpp4r/client'
require 'yaml'
require 'rbcmd'
include Jabber


#inspired by xmpp4r example client
class Xxrb

	def initialize
		@cli_cmds  = {}
		@xmpp_cmds = {}
	end

	def cli_cmds
		@cli_cmds
	end

	def xmpp_cmds
		@xmpp_cmds
	end

	def client
		unless @client
			@client = Client.new
		end
		@client
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
		result += "I offer the following functionality:\n"
		result += cmds(@cli_cmds)
	end

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
		result = cmds
	end

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

	def start_xmpp_interface
		if @client
			@client.add_message_callback { |message|
				unless message.type == :error
					puts message.from.to_s+" \""+message.body.strip+"\""
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
			result = "listening for commands from xmpp"
		else
			result = "not yet connected, please connect first"
		end
	end

	def connect(jid = nil, password = nil)
		unless jid.nil? and password.nil?
			@jid, @password = JID.new(jid), password
			@jid.resource=("xxrb") unless @jid.resource
			@client = Client.new(@jid)
			@client.connect
			@client.auth_sasl(Jabber::SASL::Base.new,@password)
		else
			file = File.open('login.conf')
			login = YAML::load(file)
			file.close
			connect(login['jid'],login['password'])
		end
		start_xmpp_interface
	end

	def presence_online(message = nil)
		presence = Presence.new
		presence.set_status(message) if message
		@client.send(presence)
	end


end

