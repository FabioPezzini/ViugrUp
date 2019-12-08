require 'network_interface'
require 'fileutils'

class NetworkManager
  def initialize(machine_base,provider,public_net_name,public_net_ip,private_net_ip)
    @pub_subn_VD = {} #Hashmap that contains machine in same sub if Docker cont e VM machines
    @pub_subn_DD = {}

    @machine_base = machine_base
    @provider = provider
    @public_network_name = public_net_name
    @public_network_ip = public_net_ip
    @private_network_ip = private_net_ip

    check_pub_subn
  end

  # Check if there are machine in the same subn
  def check_pub_subn
    for i in 0..(@machine_base.length-2)
      for b in i+1..(@machine_base.length-1)
        if @public_network_name[i].to_s.casecmp('') != 0
          if @public_network_name[i].to_s.casecmp(@public_network_name[b].to_s) == 0 ## Se sono nella stessa subn (True)
            if (@provider[i].to_s.casecmp('DOCKER') == 0 && @provider[b].to_s.casecmp(@provider[i].to_s) == 0) #Se sono entrambi Docker
              if @pub_subn_DD.key?(@public_network_name[i].to_s) #Se l'hash contiene gia' la subn
                @pub_subn_DD[@public_network_name[i].to_s].push(i.to_s, b.to_s)
              else
                @pub_subn_DD[@public_network_name[i].to_s] = [i.to_s, b.to_s]
              end
            else #Sono docker e virtualbox
              if @pub_subn_VD.key?(@public_network_name[i].to_s) #Se l'hash contiene gia' la subn
                @pub_subn_VD[@public_network_name[i].to_s].push(i.to_s, b.to_s)
              else
                @pub_subn_VD[@public_network_name[i].to_s] = [i.to_s, b.to_s]
              end
            end
          end
        end
      end
    end
  end

  def add_public_network(file, count)
    if @public_network_ip[count].to_s.casecmp('') != 0
      subn = is_in_a_subn?(count)
      if subn != '' #SE QUINDI LA MACCHINA E' IN UNA SUBN
        bridge_interface = 'br-' + create_docker_network(subn).to_s
        if @provider[count].to_s.casecmp('VIRTUALBOX') == 0
          ip = @gateway.to_s[0..-2] + '4'+ count.to_s

          file.puts '    vm' + count.to_s + '.vm.network "public_network", bridge:"' + bridge_interface.delete(' ').to_s + '", ip:"' + ip.to_s + '"'
        else #E' docker
          file.puts '    vm' + count.to_s + '.vm.network "public_network", type: "dhcp", bridge:"' + bridge_interface.delete(' ').to_s + '", docker_network_gateway:"' + @gateway.to_s + '",docker_network__ip_range: "' + @gateway.to_s + '/24"'
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

  def is_in_a_subn?(count)
    @pub_subn_VD.each do |key, value|
      value.each do |num|
        if num.to_i == count.to_i
          return key
        end
      end
    end
    ''
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
      @gateway = get_docker_network(network_id.to_s)
      return network_id
    end
  end

  def check_docker_network(sub_name)
    cmd = 'docker network ls'

    Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
      @prova = stdout.read
    end
    return @prova[/\n(.*?)#{sub_name}/, 1]
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


  def add_private_network(file,count) # DA CAMBIARE, BISOGNA FARE IL PROVISIONING CON SHELL e solo con vbox
    if @private_network_ip[count].to_s.casecmp('') != 0 #Se c'e' una private network
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


  def get_pub_subn_VD
    @pub_subn_VD
  end

end
