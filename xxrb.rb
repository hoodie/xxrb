
require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'
require 'yaml'
require 'rbcmd'
require 'xep49-storer'
require 'chatsession'

require 'modules/commandline'
include Jabber


class Xxrb
  
  include Commandline

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

  def xmpp_fallback ( command, args, jid )
    command + ' is not a command' 
  end


  # Begin of getters
  def roster
    get_roster
    @roster_string
  end

  # End of getters


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
      @jid.resource = @config['defaults']['resource'] unless @jid.resource
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

#  def startsession(recipient, type = :chat)
#    quit = false
#    while not quit
#      line = gets.strip!
#
#      quit = true if line == '.'
#      unless quit
#        output = send(type, recipient)
#        puts output unless output.nil?
#      end
#    end
#  end

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
