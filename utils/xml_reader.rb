require 'colorize'
require 'nokogiri'

class XmlReader
  def initialize(project_name, lab)
    @project_name = project_name.to_s
    @lab_name = lab.to_s
    parent_directory = File.expand_path(".", Dir.pwd)
    if $os.to_s.eql? 'windows'
      @lab_path = parent_directory + '\\labs\\' + @lab_name + '.xml'
      @separator = '\\'
      @boxes_dir = parent_directory + '\\images\\' + 'boxes.txt'
    else
      @lab_path = parent_directory + '/labs/' + @lab_name + '.xml'
      @separator = '/'
      @boxes_dir = parent_directory + '/images/' + 'boxes.txt'
    end
  end

  def scan
    createVfile
    puts @lab_path
    file = File.read(@lab_path)
    doc = Nokogiri::XML(file)
    file = File.open($path_folder + @separator + @project_name + @separator + 'Vagrantfile', 'a')
    count = 0
    doc.xpath('//machine').each do |machine|
      @machine_name = machine.at_xpath('machine_name').content
      @machine_base = machine.at_xpath('machine_base').content
      @machine_version = machine.at_xpath('version').content
      @provider = machine.at_xpath('provider').content
      if machine.at_xpath('public_network') != nil
        @public_network = machine.at_xpath('public_network').content
      end
      create_machine(file, count)
      count += 1
    end
    close_vagrant_file(file)
  end

  # Create the Vagrantfile
  def createVfile
    if File.exist?($path_folder + @separator + @project_name)
      to_print = 'PROJECT ALREDY EXIST'
      puts to_print.colorize(:green)
    else
      Dir.mkdir($path_folder + @separator + @project_name)
      file = File.open($path_folder + @separator + @project_name + @separator + 'Vagrantfile', 'w')
      write_basic_vfile(file)
      to_print = 'Config file CREATED!'
      puts to_print.colorize(:light_blue)
    end
  end

  # Insert in Vagrantfile the basic lines
  def write_basic_vfile(file)
    file.puts 'Vagrant.configure("2") do |config|'
    file.close
  end
  
  def create_machine(file, count)
    file.puts '  config.vm.define "' + @machine_name + '" do |vm' + count.to_s + '|'
    add_machine_name(file, count) if @machine_name != nil
    add_machine_provider(file, count) if @provider != nil
    add_public_network(file,count) if @public_network != nil



    file.puts '  end'
  end

  def add_public_network(file,count)
    if $os.to_s.eql? 'windows'
      #todo IMPOSTAZIONI PER WINDOWS
    else
      if @public_network.casecmp('DHCP') == 0 #true
        file.puts '    vm' + count.to_s + '.vm.network "public_network", bridge: ["wlan0", "eth0"]'
      else
        file.puts '    vm' + count.to_s + '.vm.network "public_network", ip:' + '"' + @public_network + '"' + ',bridge: ["wlan0", "eth0"]'
      end
    end
  end

  def add_machine_name(file, count)
    file.puts '    vm' + count.to_s + '.vm.hostname = "' + @machine_name + '"'
    file.puts '    vm' + count.to_s + '.vm.boot_timeout = 60'
  end

  def add_machine_provider(file, count)
    if @provider.casecmp('VIRTUALBOX') == 0 #True
      box = search_box.to_s.gsub("\n", '')
      if box.to_s == 'nil' #MANDA ERRORE
      else
        file.puts '    vm' + count.to_s + '.vm.box = "' + box + '"'
      end
      file.puts '    vm' + count.to_s + '.vm.provider "virtualbox"'
    end
  end

  def search_box
    if @machine_version == nil
      to_search = @machine_base
    else
      to_search = @machine_base + @machine_version
    end
    File.open(@boxes_dir, 'r') do |f|
      f.each_line do |line|
        return line.to_s.partition(': ').last if line.match(/^#{to_search}/)
      end
    end
    'nil'
  end

  def close_vagrant_file(file)
    file.puts 'end'
    file.close
  end


end
