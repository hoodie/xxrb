class XEP49

	def initialize(bot)
		@bot = bot
	end
		

	def store(jid, property, value)
		stanza = xep49_build_per_user(:set, jid, property, value)
		if @bot.connected
			@bot.exec(stanza)
			"trying not to forget"
		else
			"not connected therefore can't send stanza \""+ stanza +"\""
		end
	end	


	def load(jid, property)
		stanza = xep49_build_per_user(:get, jid, property)
		if @bot.connected
			@bot.exec(stanza)
			"seems that I forgot"
		else
			"not connected therefore can't send stanza \""+ stanza +"\""
		end
	end	

	def load_all
		internal=REXML::Element.new('xxrb')
		internal.add_attribute("xmlns","xxrb:peruser")

		stanza = xep49_build_query(:get, internal)
		@bot.exec(stanza)
	end


	def xep49_build_per_user(type, jid, property, value = nil)
		internal=REXML::Element.new('xxrb')
		internal.add_attribute("xmlns","xxrb:peruser")

		user=REXML::Element.new('user')
		user.add_attribute("jid",jid.strip.to_s)

		property = REXML::Element.new(property)
		if value
			property.add_text(value)
		end

		user.add(property)
		internal.add(user)

		iq = xep49_build_query(type, internal)
	end


	def xep49_build_query(type, internal = nil)
		if type == :get or type == :set
			iq = Iq.new(type)

			query=REXML::Element.new('query')
			query.add_attribute("xmlns","jabber:iq:private")

			if internal
				query.add(internal)
			end
			
			iq.query=query
		end
		iq
	end

end
