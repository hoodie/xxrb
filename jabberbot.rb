#!/usr/bin/ruby

require 'xxrb'

bot = Xxrb.new

=begin
Here we start defining new commands and add them to the bot
=end

do_help = RbCmd.new(:help, :cli)
def do_help.action
	if @args == "me"
		result = "May I be of some assistence?"
	else
		result = "This is meant to help you"
	end
end

bot.add_cmd(do_help)
bot.start_cli
