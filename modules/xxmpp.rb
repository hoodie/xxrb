module Xxmpp


  # Begin of getters
  def roster
    get_roster
    @roster_string
  end

  # End of getters


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

  def iq_dispatch(iq)
    #iq.root.elements.each('//user') { |e| e.to_s }
    puts ">>> " + iq.to_s
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
