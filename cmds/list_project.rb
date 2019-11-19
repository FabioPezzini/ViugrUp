require 'colorize'
require './utils/vagrantfile_reader'
require './utils/project_status'

class ListProject
  def initialize(args)
    parse_args(args)
  end

  # Check if the flag passed exists
  def parse_args(args)
    begin
      if %w[-up -all].include?args[0]
        parse_flag(args)
      else
        raise WrongCommandSyntax, 'No existing flag for the command'
      end
    end
  rescue WrongCommandSyntax => e
    puts e.message.colorize(:red)
  end

  def parse_flag(args)
    list_all if args[0] == '-all'
    list_active if args[0] == '-up'
  end

  # Print the machines of every project in Viugrup folder
  def list_all
    to_print = 'ViugrUp'
    puts to_print.colorize(:green)
    projects = Dir.entries($path_folder).reject { |f| File.directory?(f) || f[0].include?('.') }
    projects.each do |x|
      output_status(x)
    end
  end

  # Print only the running machines of every project in Viugrup folder
  def list_active
    to_print = 'ViugrUp - Running...'
    puts to_print.colorize(:green)

    ps = ProjectStatus.new
    projects = Dir.entries($path_folder).reject { |f| File.directory?(f) || f[0].include?('.') }
    projects.each do |x|
      output_status(x) if ps.project_status(x.to_s) == 1
    end
  end

  # Default output for list commands
  def output_status(project)
    v_reader = VagrantFileReader.new(project)
    v_reader.read
    print '|__'
    puts project.to_s
    hostname = v_reader.get_hostname
    box = v_reader.get_box
    count = 0
    hostname.each do |host|
      print '|'
      print '     |__' + ' Hostname:' + host.to_s + "\t"
      print 'Box:' + box[count].to_s
      count += 1
      puts ''
    end
  end
end