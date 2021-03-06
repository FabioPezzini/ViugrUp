require 'colorize'
require 'fileutils'

class RemoveProject
  def initialize(args)
    if args.length == 1
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
      remove_all(args)
    else
      begin
        raise NotFound, 'Project ' + args[0].to_s + "doesn't exist"
      rescue NotFound => e
        puts e.message.colorize(:red)
      end
    end
  end

  # Stop the machines in the project
  def remove_all(args)
    path_to_folder = $path_folder + '/' + args[0].to_s
    puts 'Are you sure you want delete this project?[Y,n]?'
    dec = gets.chomp
    if dec.to_s.casecmp('Y') == 0
      cmd = 'cd ' + path_to_folder.to_s + ';' + ' vagrant destroy -f'
      Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
        while (line = stdout.gets)
          puts line
        end
      end
      FileUtils.rm_rf(path_to_folder)
      to_print = 'INFO:' + 'Project deleted successfully'
      puts to_print.colorize(:light_blue)
    else
      puts 'Operation canceled'
    end
  end
end
