
require 'xmpp4r'
require 'xmpp4r/roster/helper/roster'
require 'yaml'
require 'rbcmd'

require 'modules/xep49-storer'
require 'modules/xxmpp'
include Jabber


class Xxrb
  
  include Xxmpp

  attr_reader :connected, :cli_cmds, :xmpp_cmds, :storer, :client

  def initialize
    @cli_cmds  = {}
    @xmpp_cmds = {}
    @connected = false

    #@storer = XEP49.new(self)

    load_config
    
    if @config['options']['autologin']
      puts connect(@jid,@password)
      puts status(@config['defaults']['status'])
      puts start_xmpp_interface
      puts "\n"
    end
  end

  def load_config
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
  end

  # welcoming message for cli users
  def hello
    result = "Hello, I am a Jabber Bot. "
    result += "\n" + cmds(@cli_cmds)
  end

  def xmpp_fallback ( command, args, jid )
    command + ' is not a command' 
  end

  def cli_fallback ( command, args, jid )
    command + ' is not a command'
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
          action = lambda{ cli_fallback(command, args, jid) }
        else
          action = lambda{ xmpp_fallback(command, args, jid) }
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


  # Parse commandline input and deligate to either xmpp_cmds or cli_cmds
  def take_cmd(pool, line, jid = nil)
    command, args = line.split(' ', 2) unless line.nil? 
    if command	
      unless pool[command.to_sym] == nil
        action = lambda { pool[command.to_sym].execute(args, jid) }
      else
        if pool == @cli_cmds
          action = lambda{ cli_fallback(command, args, jid) }
        else
          action = lambda{ xmpp_fallback(command, args, jid) }
        end
      end
    else
      action = proc {}
    end
    action
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


end
