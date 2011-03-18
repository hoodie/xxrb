module XEP49

	# has nothing to do with "remove" 
	def store()
		iq = Iq.new(:set)
		query=REXML::Element.new('query')
		query.add_attribute("xmlns","jabber:iq:private")

		internal=REXML::Element.new('xxrb')
		internal.add_attribute("xmlns","xxrb:peruser")
		
		user=REXML::Element.new('user')
		user.add_attribute("jid","hendrik@hoodie.de")

		remindme = REXML::Element.new('remindme')
		remindme.add_text("buy some milk")

		user.add(remindme)
		internal.add(user)
		query.add(internal)
		iq.query=query

		puts iq
		@client.send(iq)
	end


	def xep49_load
		iq = Iq.new(:get)
		query=REXML::Element.new('query')
		query.add_attribute("xmlns","jabber:iq:private")

		internal=REXML::Element.new('xxrb')
		internal.add_attribute("xmlns","xxrb:peruser")

		query.add(internal)
		iq.query=query

		puts iq
		@client.send(iq)
	end

end
