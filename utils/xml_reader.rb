require 'colorize'
require 'nokogiri'
require 'network_interface'
require 'fileutils'

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

    @machine_name = Array[]
    @machine_base = Array[]
    @machine_version = Array[]
    @provider = Array[]
    @public_network_name = Array[]
    @public_network_ip = Array[]
    @private_network_ip = Array[]
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
          if network.at_xpath('network_name') != nil
            @public_network_name.push(network.at_xpath('network_name').content)
          else
            @public_network_name.push('')
          end
          @public_network_ip.push(network.at_xpath('ip').content)
        end
      else
        @public_network_name.push('')
        @public_network_ip.push('')
      end
      if machine.at_xpath('private_network') != nil
        machine.xpath('//private_network').each do |network|
          @private_network_ip.push(network.at_xpath('ip').content)
        end
      else
        @private_network_ip.push('')
      end
    end
    create_machine(file)
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

  def create_machine(file)
    pub_subn_VD = {} #Hashmap that contains machine in same sub if Docker cont e VM machines
    pub_subn_DD = {}
    check_pub_subn(pub_subn_VD, pub_subn_DD)
    for i in 0..(@machine_base.length-1)
      file.puts '  config.vm.define "' + @machine_name[i].to_s + '" do |vm' + i.to_s + '|'
      add_machine_name(file, i) if @machine_name[i].to_s != nil
      add_machine_provider(file, i) if @provider[i].to_s != nil
      add_public_network(file, i, pub_subn_VD) if !@public_network_ip[i].nil?
      add_private_network(file, i) if !@private_network_ip[i].nil?
      file.puts '  end'
    end

    to_print = 'Project created succesfully!'
    puts to_print.colorize(:light_blue)
  end

  # Check if there are machine in the same subn
  def check_pub_subn(pub_subn_VD, pub_subn_DD)
    for i in 0..(@machine_base.length-2)
      for b in i+1..(@machine_base.length-1)
        if @public_network_name[i].to_s.casecmp('') != 0
          if @public_network_name[i].to_s.casecmp(@public_network_name[b].to_s) == 0 ## Se sono nella stessa subn (True)
            if (@provider[i].to_s.casecmp('DOCKER') == 0 && @provider[b].to_s.casecmp(@provider[i].to_s) == 0) #Se sono entrambi Docker
              if pub_subn_DD.key?(@public_network_name[i].to_s) #Se l'hash contiene gia' la subn
                pub_subn_DD[@public_network_name[i].to_s].push(i.to_s, b.to_s)
              else
                pub_subn_DD[@public_network_name[i].to_s] = [i.to_s, b.to_s]
              end
            else #Sono docker e virtualbox
              if pub_subn_VD.key?(@public_network_name[i].to_s) #Se l'hash contiene gia' la subn
                pub_subn_VD[@public_network_name[i].to_s].push(i.to_s, b.to_s)
              else
                pub_subn_VD[@public_network_name[i].to_s] = [i.to_s, b.to_s]
              end
            end
          end
        end
      end
    end
  end

  def add_private_network(file,count)
    if @private_network_ip[count].to_s.casecmp('') != 0
    if @provider[count].to_s.casecmp('VIRTUALBOX') == 0
      if @private_network_ip[count].to_s.casecmp('DHCP') == 0 #true
        file.puts '    vm' + count.to_s + '.vm.network "private_network", type:"dhcp"'
      else
        file.puts '    vm' + count.to_s + '.vm.network "private_network", ip:' + '"' + @private_network_ip[count].to_s + '"'
      end
    elsif @provider[count].to_s.casecmp('DOCKER') == 0
      if @private_network_ip[count].to_s.casecmp('DHCP') == 0 #true
        file.puts '    vm' + count.to_s + '.vm.network "private_network",type: "dhcp", docker_network__internal: true'
      else
        file.puts '    vm' + count.to_s + '.vm.network "private_network", ip: "'+@private_network_ip[count].to_s+'", docker_network__internal: true'
      end
    end
      end

  end

  def add_public_network(file, count, pub_subn_VD)
    if @public_network_ip[count].to_s.casecmp('') != 0
    subn = is_in_a_subn?(count, pub_subn_VD)
    if subn != '' #SE QUINDI LA MACCHINA E' IN UNA SUBN
      bridge_interface = 'br-' + create_docker_network(subn).to_s
      if @provider[count].to_s.casecmp('VIRTUALBOX') == 0
        ip = @gateway.to_s[0..-2] + '4'+ count.to_s

        file.puts '    vm' + count.to_s + '.vm.network "public_network", bridge:"' + bridge_interface.to_s + '", ip:"' + ip.to_s + '"'
      else #E' docker
        file.puts '    vm' + count.to_s + '.vm.network "public_network", type: "dhcp", bridge:"' + bridge_interface.to_s + '", docker_network_gateway:"' + @gateway.to_s + '",docker_network__ip_range: "' + @gateway.to_s + '/24"'
      end
    else
      if @provider[count].to_s.casecmp('VIRTUALBOX') == 0
        if @public_network_ip[count].to_s.casecmp('DHCP') == 0 #true
          file.puts '    vm' + count.to_s + '.vm.network "public_network", bridge: [' + get_bridges + ']'
        else
          file.puts '    vm' + count.to_s + '.vm.network "public_network", ip:' + '"' + @public_network_ip[count].to_s + '"' + ',bridge: [' + get_bridges + ']'
        end
      elsif @provider[count].to_s.casecmp('DOCKER') == 0
        if @public_network_ip[count].to_s.casecmp('DHCP') == 0 #true
        file.puts '    vm' + count.to_s + '.vm.network "public_network", type: "dhcp", bridge: [' + get_bridges + '] , docker_network_gateway:"192.168.1.1",docker_network__ip_range: "192.168.1.1/24"'
        else
          file.puts '    vm' + count.to_s + '.vm.network "public_network", ip:' + '"' + @public_network_ip[count].to_s + '"' + ',bridge: [' + get_bridges + ']'
        end
      end
    end
      end
  end

  def check_docker_network(sub_name)
    cmd = 'docker network ls'

    Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
      @prova = stdout.read
    end
    return @prova[/\n(.*?)#{sub_name}/, 1].delete(' ')
  end

  def create_docker_network(sub_name)
    network_id = check_docker_network(sub_name)
    if network_id.to_s.empty? #Se la subn non e' creata
      to_print = 'Insert the gateway for the subnet (last with .1),leave blank for autofind it (es 192.168.50.1):'
      print to_print.colorize(:green)
      @gateway = gets.chomp
      if !@gateway.to_s.empty? #Se viene fornito il gateway
        cmd = 'docker network create '+ sub_name.to_s + ' --gateway='+ @gateway.to_s + ' --subnet=' + @gateway.to_s + '/24'
        Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
        end
        return check_docker_network(sub_name).delete(' ')
      else
        @gateway = '192.168.50.0' #Usato per partire da .1
        count = 1
        @stderr = 'nan'
        while !@stderr.to_s.empty? #Faccio finche non cancello errori
          @gateway = @gateway.to_s[0..-4] + count.to_s + '.1'
          cmd = 'docker network create '+ sub_name.to_s + ' --gateway='+ @gateway.to_s + ' --subnet=' + @gateway.to_s + '/24'
          Open3.popen3(cmd) do |_stdin, stdout, stderr, _wait_thr|
            @stderr = stderr.read
          end
          count += 1
        end
        return check_docker_network(sub_name).delete(' ')
      end
    else #Se la subn esiste gia'
      @gateway = get_docker_network(network_id.to_s) #PROBLEMA QUIIIIIIIIIIIIIIIIII
      return network_id

    end
  end

  def get_docker_network(net_id)
    cmd = 'ifconfig'
    Open3.popen3(cmd) do |_stdin, stdout, stderr, _wait_thr|
      @stdout = stdout.read
    end
    interface = 'br-' + net_id.delete(' ').to_s
    lines = @stdout.split("\n")
    for i in 0..lines.length-1
      if lines[i].match(/#{interface}/)
        @to_ret =  lines[i+1][/inet (.*?) /, 1].to_s
      end
    end
    return @to_ret.to_s

  end

  def is_in_a_subn?(count, pub_subn_VD)
    pub_subn_VD.each do |key, value|
      value.each do |num|
        if num.to_i == count.to_i
          return key
        end
      end
    end
    ''
  end

  def get_bridges
    array_output = NetworkInterface.interfaces
    cleared_array = array_output.reject do |value|
      value.to_s.casecmp('LO') == 0 || value.to_s.include?('vboxnet')
    end
    if cleared_array.length > 1
      if cleared_array[0].to_s.casecmp('eth0') == 0
        cleared_array[0], cleared_array[1] = cleared_array[1], cleared_array[0]
      end
    end
    bridgeg_interfaces = '"'+ cleared_array.join('", "') + '"'
    bridgeg_interfaces
  end

  # Insert in Vagrantfile the hostname and the timeout for the boot
  def add_machine_name(file, count)
    file.puts '    vm' + count.to_s + '.vm.hostname = "' + @machine_name[count].to_s + '"'
    file.puts '    vm' + count.to_s + '.vm.boot_timeout = 60'
  end

  def add_machine_provider(file, count)
    if @provider[count].to_s.casecmp('VIRTUALBOX') == 0 #True
      box = search_box(count).gsub("\n", '')
      if box.to_s == 'nil' #MANDA ERRORE
      else
        file.puts '    vm' + count.to_s + '.vm.box = "' + box + '"'
      end
      file.puts '    vm' + count.to_s + '.vm.provider "virtualbox"'
    end
    if @provider[count].to_s.casecmp('DOCKER') == 0
      if !@docker_image[count].to_s.empty?
        search_docker_image(file, count)
      end
    end
  end

  def search_box(count)
    to_search = @machine_base[count].to_s + @machine_version[count].to_s
    File.open(@boxes_dir, 'r') do |f|
      f.each_line do |line|
        return line.to_s.partition(': ').last if line.match(/^#{to_search}/)
      end
    end
    #If it isn't in the txt, that will search in the Vagrant cloud
    return search_in_cloud(count)
  end

  def search_docker_image(file, count)
    file.puts '    vm' + count.to_s + '.vm.provider "docker" do |d|'
    file.puts '      d.image = "' + @docker_image[count].to_s + '"'
    file.puts '      d.cmd = ["tail", "-f", "/dev/null"]' #Keep container alive
    file.puts '    end'
  end

  def search_in_cloud(count)
    to_print = 'It wasn t possible to find the selected os in the `boxes.txt`, type the number of the alternative otherwise type no to end the search'
    puts to_print.colorize(:green)
    scraper = BoxGetter.new(@machine_base[count].to_s)
    name = scraper.get_name
    desc = scraper.get_desc
    counter = 0
    name.each do |x|
      puts '[SELECT NUM]' + "\t\t\t" + '[BOX NAME]' + "\t\t\t\t" + '[DESCRIPTION]'
      puts counter.to_s + "\t\t\t" + x.split(' ')[0].to_s + "\t\t" + desc[counter].to_s
      counter += 1
    end
    print 'Insert number of choosen OS: '
    @input = gets
    if @input.to_i <= counter && @input.to_i >= 0 && @input.is_a?(Integer)
      name[@input.to_i].split(' ')[0].to_s
    else
      abort_installation
      raise NotFound, 'No OS is selected, correct the scenario and retry'
    end
  end

  def close_vagrant_file(file)
    file.puts 'end'
    file.close
  end

  def abort_installation
    FileUtils.rm_rf($path_folder + @separator + @project_name)
    to_print = 'Project folder deleted'
    puts to_print.colorize(:red)
  end


end
