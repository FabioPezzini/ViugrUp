require 'colorize'

class StopProject
  def initialize(args)
    if args.length == 2
      check_projects(args)
    else
      begin
        raise WrongCommandSyntax, 'Wrong syntax for the command'
      rescue WrongCommandSyntax => e
        puts e.message
      end
    end
  end

  # Check if a project with same name passed in cli already exists
  def check_projects(args)
    projects = Dir.entries($path_folder).reject { |f| File.directory?(f) || f[0].include?('.') }
    if projects.to_s.include?args[0].to_s
      parse_args(args)
    else
      begin
        raise NotFound, 'Project ' + args[0].to_s + "doesn't exist"
      rescue NotFound => e
        puts e.message.colorize(:red)
      end
    end
  end

  # Check if the flag passed exists
  def parse_args(args)
    begin
      if %w[-all].include?args[1]
        parse_flag(args)
      else
        raise WrongCommandSyntax, 'No existing flag for the command'
      end
    end
  rescue WrongCommandSyntax => e
    puts e.message.colorize(:red)
  end

  def parse_flag(args)
    stop_all(args) if args[1] == '-all'
  end

  # Stop the machines in the project
  def stop_all(args)
    if $os.to_s.eql? 'windows'
      path_to_folder = $path_folder + '\\' + args[0].to_s
      cmd = 'powershell.exe cd ' + path_to_folder.to_s + ';' + ' vagrant halt'
    else
      path_to_folder = $path_folder + '/' + args[0].to_s
      cmd = 'cd ' + path_to_folder.to_s + ';' + ' vagrant halt'
    end
    Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
      while (line = stdout.gets)
        puts line
      end
    end
    to_print = 'INFO:' + 'Project stopped successfully'
    puts to_print.colorize(:light_blue)
  end
end