require 'colorize'
require './utils/project_status'

class RunProject
  def initialize(args)
    if args.length == 2
      check_projects(args)
    else
      begin
        raise WrongCommandSyntax, 'Wrong syntax for the command'
      rescue WrongCommandSyntax => e
        puts e.message.colorize(:red)
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
    run_all(args) if args[1] == '-all'
  end

  def run_all(args)
    ps = ProjectStatus.new

    path_to_folder = $path_folder + '/' + args[0].to_s
    value = ps.project_status(path_to_folder)

    cmd = 'cd ' + path_to_folder.to_s + ';' + ' vagrant up' if value == -1
    cmd = 'cd ' + path_to_folder.to_s + ';' + ' vagrant reload --provision' if value == 0
    Open3.popen3(cmd) do |_stdin, stdout, stderr, _wait_thr|
      while (line = stdout.gets)
        puts line
      end
      puts stderr.read
    end
    to_print = 'INFO:' + 'Project started successfully'
    puts to_print.colorize(:light_blue)
  end
end
