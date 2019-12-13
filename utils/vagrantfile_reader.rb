# frozen_string_literal: true

class VagrantFileReader
  def initialize(folder)
    path_project = $path_folder + '/' + folder.to_s
    @file_path = path_project + '/' + 'Vagrantfile'
  end

  def read
    @hostname = Array[]
    @box = Array[]
    File.open(@file_path, 'r') do |f|
      f.each_line do |line|
        @hostname.push(line.scan(/"(.*)"/)[0][0]) if line =~ /hostname/
        @box.push(line.scan(/"(.*)"/)[0][0]) if line =~ /box/
      end
    end
  end

  def search_vm(vm_name)
    value = false
    vm = '"' + vm_name + '"'
    File.open(@file_path, 'r') do |f|
      f.each_line do |line|
        value = true if line =~ /#{vm}/
      end
    end
    value
  end

  def already_puppet(vm_name)
    value = false
    vm = '"' + vm_name + '.pp' + '"'
    File.open(@file_path, 'r') do |f|
      f.each_line do |line|
        value = true if line =~ /#{vm}/
      end
    end
    value
  end

  def forward_port_webserver(vm_name)
    vm =  'config.vm.define '+'"' + vm_name + '"'
    count = 0
    File.open(@file_path, 'r+') do |f|
      f.each_line do |line|
        if line =~ /#{vm}/
          @custom = line.scan(/\|([^\.]+)\|/)[0][0]
          count += 1
        end
        if(count.to_i != 0)
          if (count.to_i == 3)
            pos = f.pos
            rest = f.read
            f.seek pos
            f.puts '    ' + @custom.to_s + '.vm.network ' + '"' + 'forwarded_port' + '", ' + 'guest: 80, host: 8080'
            f.write rest
          else
            count += 1
          end
        end
      end
    end
  end

  def update_with_provision(vm_name)
    vm =  'config.vm.define '+'"' + vm_name + '"'
    count = 0
    File.open(@file_path, 'r+') do |f|
      f.each_line do |line|
        if line =~ /#{vm}/
          @custom = line.scan(/\|([^\.]+)\|/)[0][0]
          count += 1
        end
        if(count.to_i != 0)
          if (count.to_i == 3)
            pos = f.pos
            rest = f.read
            f.seek pos
            write_provision(vm_name,f)
            f.write rest
          else 
            count += 1
          end
        end
      end
    end
  end

  def write_provision(vm_name,file)
    file.puts ''
    file.puts '    ' + @custom.to_s + '.vm.provision "shell", inline: "sudo apt-get update && sudo apt-get install -y puppet"'
    file.puts '    ' + @custom.to_s + '.vm.provision' + ' "' + 'puppet' + '" ' + 'do |puppet|'
    file.puts '      ' + "puppet.manifests_path = 'puppet/manifests'"
    file.puts '      ' + "puppet.module_path = 'puppet/modules'"
    file.puts '      ' + "puppet.manifest_file = " + '"' + vm_name.to_s + '.pp' + '"'
    file.puts '    ' + 'end'

  end
  def get_hostname
    @hostname
  end

  def get_box
    @box
  end
end
