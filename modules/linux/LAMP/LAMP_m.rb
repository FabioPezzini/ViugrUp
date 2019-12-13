require 'fileutils'

class Lamp
  def initialize(pro_name,name_vm)
    @path_proj = $path_folder + '/' + pro_name.to_s
    @path_proj_puppet = $path_folder + '/' + pro_name.to_s + '/puppet'
    @name_vm = name_vm
    install_apache
    vr = VagrantFileReader.new(pro_name)
    vr.forward_port_webserver(name_vm)
  end

  def install_apache
    @path_proj_apache = @path_proj_puppet  + '/modules/apache'
    value = File.exist?(@path_proj_apache)
    if value == false
      Dir.mkdir(@path_proj_apache)
      Dir.mkdir(@path_proj_apache  + '/manifests')
      FileUtils.cp("modules/linux/LAMP/apache.pp", @path_proj_apache + '/manifests')
      File.rename(@path_proj_apache  + '/manifests/apache.pp',@path_proj_apache +'/manifests/init.pp')
    end
    puts 'APACHE INSTALLED IN ' + @name_vm.to_s
    install_bootstrap
  end

  def install_bootstrap
    @path_proj_bootstrap = @path_proj_puppet + '/modules/bootstrap'
    value = File.exist?(@path_proj_bootstrap)
    if value == false
      Dir.mkdir(@path_proj_bootstrap)
      Dir.mkdir(@path_proj_bootstrap +'/manifests')
      FileUtils.cp("modules/linux/LAMP/bootstrap.pp",@path_proj_bootstrap +'/manifests')
      File.rename(@path_proj_bootstrap +'/manifests/bootstrap.pp',@path_proj_bootstrap +'/manifests/init.pp')
    end
    puts 'BOOTSTRAP INSTALLED IN ' + @name_vm.to_s
    install_mysql
  end

  def install_mysql
    @path_proj_mysql = @path_proj_puppet +'/modules/mysql'
    value = File.exist?(@path_proj_mysql)
    if value == false
      Dir.mkdir(@path_proj_mysql)
      Dir.mkdir(@path_proj_mysql +'/manifests')
      FileUtils.cp("modules/linux/LAMP/mysql.pp",@path_proj_mysql + '/manifests')
      File.rename(@path_proj_mysql + '/manifests/mysql.pp',@path_proj_mysql + '/manifests/init.pp')
    end
    puts 'MYSQL INSTALLED IN ' + @name_vm.to_s
    install_php
  end

  def install_php
    @path_proj_php = @path_proj_puppet + '/modules/php'
    value = File.exist?(@path_proj_php)
    if value == false
      Dir.mkdir(@path_proj_php)
      Dir.mkdir(@path_proj_php +'/manifests')
      FileUtils.cp("modules/linux/LAMP/php.pp",@path_proj_php +'/manifests')
      File.rename(@path_proj_php + '/manifests/php.pp',@path_proj_php + '/manifests/init.pp')
    end
    puts 'PHP INSTALLED IN ' + @name_vm.to_s
    install_tools
  end

  def install_tools
    @path_proj_tools = @path_proj_puppet +'/modules/tools'
    value = File.exist?(@path_proj_tools)
    if value == false
      Dir.mkdir(@path_proj_tools)
      Dir.mkdir(@path_proj_tools +'/manifests')
      FileUtils.cp("modules/linux/LAMP/tools.pp",@path_proj_tools +'/manifests')
      File.rename(@path_proj_tools + '/manifests/tools.pp',@path_proj_tools +'/manifests/init.pp')
    end
    create_vhost
  end

  def create_vhost
    value = File.exist?(@path_proj_puppet  +'/templates')
    if value == false
      Dir.mkdir(@path_proj_puppet + '/templates')
      FileUtils.cp("modules/linux/LAMP/vhost",@path_proj_puppet +'/templates/vhost')
    end
    create_src
  end

  def create_src
    value = File.exist?(@path_proj +'/src')
    if value == false
      Dir.mkdir(@path_proj + '/src')
      FileUtils.cp("modules/linux/LAMP/index.html",@path_proj +'/src/index.html')
      FileUtils.cp("modules/linux/LAMP/info.php",@path_proj +'/src/info.php')
    end
    append_default
  end

  def append_default
    @file_manifest = @path_proj_puppet +'/manifests/' + @name_vm.to_s + '.pp'
    to_append = File.read("modules/linux/LAMP/default.txt")
    if File.zero?(@file_manifest)
    File.open(@file_manifest, 'a') do |handle|
      handle.puts to_append
    end
    puts 'LAMP INSTALLED IN ' + @name_vm.to_s
    else
      puts 'Puppet file is not empty'
      end
    end
end
