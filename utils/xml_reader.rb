require 'colorize'
require 'nokogiri'
require 'fileutils'

require './utils/network_man'


class XmlReader
  def initialize(project_name, lab)

    @project_name = project_name.to_s
    @lab_name = lab.to_s
    parent_directory = File.expand_path(".", Dir.pwd)

    @lab_path = parent_directory + '/labs/' + @lab_name + '.xml'
    @separator = '/'
    @boxes_dir = parent_directory + '/images/' + 'boxes.txt'


    @machine_name = Array[]
    @machine_base = Array[]
    @machine_version = Array[]
    @provider = Array[]
    @public_network_ip = Array[]
    @private_network_ip = Array[]
    @private_network_name = Array[]
    @docker_image = Array[]
  end

  def scan
    createVfile
    file = File.read(@lab_path)
    doc = Nokogiri::XML(file)
    file = File.open($path_folder + @separator + @project_name + @separator + 'Vagrantfile', 'a')
    doc.xpath('//machine').each do |machine|
      @machine_name.push(machine.at_xpath('machine_name').content)
      if machine.at_xpath('machine_base') != nil
        @machine_base.push(machine.at_xpath('machine_base').content)
      else
        @machine_base.push('')
      end
      if machine.at_xpath('docker_image') != nil
        @docker_image.push(machine.at_xpath('docker_image').content)
      else
        @docker_image.push('')
      end
      if machine.at_xpath('version') != nil
        @machine_version.push(machine.at_xpath('version').content)
      else
        @machine_version.push('')
      end
      @provider.push(machine.at_xpath('provider').content)
      if machine.at_xpath('public_network') != nil
        machine.xpath('//public_network').each do |network|
          @public_network_ip.push(network.at_xpath('ip').content)
        end
      else
        @public_network_ip.push('')
      end
      if machine.at_xpath('private_network') != nil
        machine.xpath('//private_network').each do |network|
          if network.at_xpath('network_name') != nil
            @private_network_name.push(network.at_xpath('network_name').content)
          else
            @private_network_name.push('')
          end
          @private_network_ip.push(network.at_xpath('ip').content)
        end
      else
        @private_network_name.push('')
        @private_network_ip.push('')
      end
    end
    create_machine(file)
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

  def create_machine(file)
    @net_m = NetworkManager.new(@machine_base,@provider,@public_network_ip,@private_network_ip,@private_network_name)
    for i in 0..(@machine_base.length-1)
      file.puts '  config.vm.define "' + @machine_name[i].to_s + '" do |vm' + i.to_s + '|'
      add_machine_name(file, i) if @machine_name[i].to_s != nil
      add_machine_provider(file, i) if @provider[i].to_s != nil
      add_public_network(file, i) if !@public_network_ip[i].nil?
      add_private_network(file, i) if !@private_network_ip[i].nil?
      add_shell_provision(file,i)
      file.puts '  end'
    end

    close_vagrant_file(file)
    last_end
    to_print = 'Project created succesfully!'
    puts to_print.colorize(:light_blue)
  end

  def last_end
    file = File.open($path_folder + @separator + @project_name + @separator + 'Vagrantfile', 'a')
    file.puts 'end'
    file.close
  end

  def add_shell_provision(file,count)
    if @machine_base[count].to_s.casecmp('WINDOWS') == 0 #Se e' windows.xml
      path_chocolatey = Dir.pwd.to_s + '/modules/windows/shell/InstallChocolatey.ps1'
      file.puts '    vm' + count.to_s + '.vm.provision :shell, privileged: "true", :path => "' + path_chocolatey.to_s + '"'
    end
  end


  def add_private_network(file,count) # DA CAMBIARE, BISOGNA FARE IL PROVISIONING CON SHELL e solo con vbox
    @net_m.add_private_network(file,count)
  end

  def add_public_network(file, count)
    @net_m.add_public_network(file,count)
  end

  # Insert in Vagrantfile the hostname and the timeout for the boot
  def add_machine_name(file, count)
    file.puts '    vm' + count.to_s + '.vm.hostname = "' + @machine_name[count].to_s + '"'
    file.puts '    vm' + count.to_s + '.vm.boot_timeout = 120'
    if @machine_base[count].to_s.casecmp('WINDOWS') == 0 #se il box e' Windows
      file.puts '    vm' + count.to_s + '.vm.guest = :windows'
    end
  end

  def add_machine_provider(file, count)
    if @provider[count].to_s.casecmp('VIRTUALBOX') == 0 #True
      box_getter = BoxGetter.new
      box = box_getter.search_box(@machine_base[count],@machine_version[count],@boxes_dir).gsub("\n", '')
      if box.to_s == 'nil' #MANDA ERRORE
      else
        file.puts '    vm' + count.to_s + '.vm.box = "' + box + '"'
      end
      file.puts '    vm' + count.to_s + '.vm.provider "virtualbox"'
    end
    if @provider[count].to_s.casecmp('DOCKER') == 0
      if !@docker_image[count].to_s.empty?
        file.puts '    vm' + count.to_s + '.vm.box = "' + @docker_image[count].to_s + '"'
        file.puts '    vm' + count.to_s + '.vm.provider "docker"'
      end
    end
  end

  def close_vagrant_file(file)
    file.close
  end

  def abort_installation
    FileUtils.rm_rf($path_folder + @separator + @project_name)
    to_print = 'Project folder deleted'
    puts to_print.colorize(:red)
  end
end