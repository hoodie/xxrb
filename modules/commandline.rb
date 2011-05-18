module Commandline
  
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

  # welcoming message for cli users
  def hello
    result = "Hello, I am a Jabber Bot. "
    result += "\n" + cmds(@cli_cmds)
  end

end
