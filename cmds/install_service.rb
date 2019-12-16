require './utils/vagrantfile_reader'
require './modules/linux/MYSQL/MYSQL_m'
require './modules/linux/APACHE/APACHE_m'

class InstallService
  def initialize(args)
    if args.length == 3
      parse_args(args)
    else
      begin
        raise WrongCommandSyntax, 'Wrong syntax for the command'
      rescue WrongCommandSyntax => e
        puts e.message
      end
    end
  end

  def parse_args(args)
    begin
      @path_project = $path_folder + '/' + args[0].to_s
      raise NotFound, "Project doesn't exist" unless Dir.exist?(@path_project)

      @name_vm = args[1].to_s
      @file_name = args[0].to_s
      @module = args[2].to_s
      raise NotFound, 'Vm not include in the specified project' unless check_vm

      create_puppet_folders

    end
  rescue StandardError => e
    puts e.message
  end

  def check_vm
    vr = VagrantFileReader.new(@file_name)
    vr.search_vm(@name_vm)
  end


  def create_puppet_folders
    path_puppet = @path_project + '/puppet'
    path_module = path_puppet + '/modules'
    value = File.exist?(path_puppet.to_s)
    if value == false
      Dir.mkdir(path_puppet)
      Dir.mkdir(path_module)
    end
    puppet_file = path_puppet + '/' + @name_vm.to_s + '.pp'
    unless File.exist?puppet_file
      File.open(puppet_file, 'w')
      add_provision_vagrantfile
    end
    parse_module
  end

  def add_provision_vagrantfile
    vr = VagrantFileReader.new(@file_name)
    vr.update_with_provision(@name_vm) unless vr.already_puppet(@name_vm)
    puts 'FILE SOVRASCRITTO!'
  end

  def parse_module
    MySQL.new(@file_name,@name_vm) if @module == '--mysql'
    Apache.new(@file_name,@name_vm) if @module == '--apache'
  end
end