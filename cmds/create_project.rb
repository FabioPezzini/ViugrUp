# frozen_string_literal: true
require 'colorize'
require 'rbconfig'
require 'vagrant-wrapper'
require 'open3'

require './exceptions/wrong_command_syntax'
require './exceptions/not_found'
require './utils/box_getter'
require './utils/xml_reader'

class CreateProject
  def initialize(args)
    @vm_name = Array[]
    @vm_box = Array[]

    if args.length == 3
      parse_args(args)
    else
      begin
        raise WrongCommandSyntax, 'Wrong syntax for the command'
      rescue WrongCommandSyntax => e
        puts e.message.colorize(:red)
      end
    end
  end

  # Check the project name and the value passed ,check if the flag passed exists
  def parse_args(args)
    begin
      @project_name = args[0]
      raise NotFound, 'Project name already used' if project_exist(@project_name)

      @num_vm = args[2]
      raise WrongCommandSyntax, 'Number of VM must be > 0' if(@num_vm.to_i < 0)

      if %w[-search -cloud -xml].include?(args[1])
        parse_flag(args)
      else
        raise WrongCommandSyntax, 'No existing flag for the command'
      end
    end
  rescue StandardError => e
    puts e.message.colorize(:red)
  end

  def parse_flag(args)
    custom_box if args[1] == '-cloud'
    search_box if args[1] == '-search'
    parse_scenario if args[1] == '-xml'
  end

  #Method to interact with the scenarios
  def parse_scenario
    xmlr = XmlReader.new(@project_name,@num_vm.to_s)
    xmlr.scan
  end

  # Used to search by OS name a box in the VagrantCloud site
  def search_box
    (1..@num_vm.to_i).each do |a|
      print '!!!> ' + 'Insert the OS for the ' + a.to_s + ' Vm: '
      @input = gets
      scraper = BoxGetter.new(@input)
      name = scraper.get_name
      desc = scraper.get_desc
      counter = 0
      name.each do |x|
        puts '[SELECT NUM]' + "\t\t\t" + '[BOX NAME]' + "\t\t\t\t" + '[DESCRIPTION]'
        puts counter.to_s + "\t\t\t" + x.split(' ')[0].to_s + "\t\t" + desc[counter].to_s
        counter += 1
      end
      print 'Insert number of choosen OS and name of the VM separate by a space (eg : ubonda 0):'
      @input = gets
      temp = @input.gsub(/\s+/m, ' ').strip.split(' ')
      @vm_name.push(temp[0].to_s)
      @vm_box.push(name[temp[1].to_i].split(' ')[0].to_s)
    end
    validate_boxes
  end

  # Ask the user to insert the boxId of the box
  def custom_box
    (1..@num_vm.to_i).each do |a|
      print '!!!> ' + 'Insert name for the ' + a.to_s + ' Vm and box name separate by a space (eg: ubonda hashicorp/precise64): '
      @input = gets
      temp = @input.gsub(/\s+/m, ' ').strip.split(' ')
      @vm_name.push(temp[0].to_s)
      @vm_box.push(temp[1].to_s)
    end
    validate_boxes
  end

  def validate_boxes
    puts 'Validating boxes...'
    counter = @num_vm - 1
    (0...@num_vm).each do |a|
      if $os.to_s.eql? 'windows'
        cmd = 'powershell.exe vagrant box add --provider virtualbox ' + @vm_box[a].to_s
      else
        cmd =  'vagrant box add --provider virtualbox ' + @vm_box[a].to_s
      end
      Open3.popen3(cmd) do |_stdin, stdout, stderr, _wait_thr|
        while (line = stdout.gets)
          puts line
        end
        err = stderr.read
        if err.include? "The box you're attempting to add already exists"
          to_print = 'INFO: BOX ' + @vm_box[a].to_s + ' alredy added'
          puts to_print.colorize(:light_blue)
        elsif err.include? 'A name is required when adding a box file directly.'
          to_print = 'WARNING: VM ' + @vm_box[a].to_s + ' unrecognized box name in Vagrant box site,insert the correct one using Vagrant or retry'
          puts to_print.colorize(:green)
          counter -= 1
        end
      end
    end
    create_vfile if counter == (@num_vm - 1)
  end

  def project_exist(name)
    projects = Dir.entries($path_folder).reject { |f| File.directory?(f) || f[0].include?('.') }
    if projects.include?name
      true
    else
      false
    end
  end

  def create_vfile
    print 'Creating config file...'
    if $os.to_s.eql? 'windows'
      path = $path_folder + '\\' + @project_name
      Dir.mkdir(path.to_s)
      file = File.open(path.to_s + '\\' + 'Vagrantfile', 'w')
    else
      path = $path_folder + '/' + @project_name
      Dir.mkdir(path.to_s)
      file = File.open(path.to_s + '/' + 'Vagrantfile', 'w')
    end
    write_file(file)
    puts 'Config file CREATED!'
  end

  def write_file(file)
    file.puts 'Vagrant.configure("2") do |config|'
    (0...@num_vm).each do |a|
      selected = 'vm' + a.to_s
      file.puts '  config.vm.define ' + '"' + @vm_name[a].to_s + '"' + ' do ' + '|' + selected + '|'
      file.puts '    ' + selected + '.vm.hostname = ' + '"' + @vm_name[a].to_s + '"'
      file.puts '    ' + selected + '.vm.box = ' + '"' + @vm_box[a].to_s + '"'
      file.puts '  end'
    end
    file.puts 'end'
    file.close
  end
end