require 'fileutils'

class Lamp
  def initialize(pro_name,name_vm)
    if $os.to_s.eql? 'windows'
      @separator = '\\'
    else
      @separator = '/'
    end
    @path_proj = $path_folder + @separator + pro_name.to_s
    @path_proj_puppet = $path_folder + @separator + pro_name.to_s + @separator +'puppet'
    @name_vm = name_vm
    install_apache
    vr = VagrantFileReader.new(pro_name)
    vr.forward_port_webserver(name_vm)
  end

  def install_apache
    @path_proj_apache = @path_proj_puppet + @separator + 'modules' + @separator + 'apache'
    value = File.exist?(@path_proj_apache)
    if value == false
      Dir.mkdir(@path_proj_apache)
      Dir.mkdir(@path_proj_apache + @separator +'manifests')
      FileUtils.cp("modules/LAMP/apache.pp",@path_proj_apache + @separator +'manifests')
      File.rename(@path_proj_apache + @separator + 'manifests' + @separator + 'apache.pp',@path_proj_apache + @separator +'manifests' + @separator + 'init.pp')
    end
    puts 'APACHE INSTALLED IN ' + @name_vm.to_s
    install_bootstrap
  end

  def install_bootstrap
    @path_proj_bootstrap = @path_proj_puppet + @separator +'modules' + @separator + 'bootstrap'
    value = File.exist?(@path_proj_bootstrap)
    if value == false
      Dir.mkdir(@path_proj_bootstrap)
      Dir.mkdir(@path_proj_bootstrap + @separator +'manifests')
      FileUtils.cp("modules/LAMP/bootstrap.pp",@path_proj_bootstrap + @separator +'manifests')
      File.rename(@path_proj_bootstrap + @separator +'manifests' + @separator +'bootstrap.pp',@path_proj_bootstrap + @separator +'manifests' + @separator +'init.pp')
    end
    puts 'BOOTSTRAP INSTALLED IN ' + @name_vm.to_s
    install_mysql
  end

  def install_mysql
    @path_proj_mysql = @path_proj_puppet + @separator +'modules' + @separator +'mysql'
    value = File.exist?(@path_proj_mysql)
    if value == false
      Dir.mkdir(@path_proj_mysql)
      Dir.mkdir(@path_proj_mysql + @separator +'manifests')
      FileUtils.cp("modules/LAMP/mysql.pp",@path_proj_mysql + @separator +'manifests')
      File.rename(@path_proj_mysql + @separator +'manifests' + @separator+'mysql.pp',@path_proj_mysql + @separator+'manifests' + @separator+'init.pp')
    end
    puts 'MYSQL INSTALLED IN ' + @name_vm.to_s
    install_php
  end

  def install_php
    @path_proj_php = @path_proj_puppet + @separator +'modules' + @separator+'php'
    value = File.exist?(@path_proj_php)
    if value == false
      Dir.mkdir(@path_proj_php)
      Dir.mkdir(@path_proj_php + @separator +'manifests')
      FileUtils.cp("modules/LAMP/php.pp",@path_proj_php + @separator +'manifests')
      File.rename(@path_proj_php + @separator+'manifests' + @separator+'php.pp',@path_proj_php + @separator+'manifests' + @separator+'init.pp')
    end
    puts 'PHP INSTALLED IN ' + @name_vm.to_s
    install_tools
  end

  def install_tools
    @path_proj_tools = @path_proj_puppet + @separator+'modules' + @separator+'tools'
    value = File.exist?(@path_proj_tools)
    if value == false
      Dir.mkdir(@path_proj_tools)
      Dir.mkdir(@path_proj_tools + @separator+'manifests')
      FileUtils.cp("modules/LAMP/tools.pp",@path_proj_tools + @separator+'manifests')
      File.rename(@path_proj_tools + @separator+'manifests' + @separator+'tools.pp',@path_proj_tools + @separator+'manifests' + @separator+'init.pp')
    end
    create_vhost
  end

  def create_vhost
    value = File.exist?(@path_proj_puppet + @separator +'templates')
    if value == false
      Dir.mkdir(@path_proj_puppet + @separator+'templates')
      FileUtils.cp("modules/LAMP/vhost",@path_proj_puppet + @separator+'templates' + @separator+'vhost')
    end
    create_src
  end

  def create_src
    value = File.exist?(@path_proj + @separator+'src')
    if value == false
      Dir.mkdir(@path_proj + @separator+'src')
      FileUtils.cp("modules/LAMP/index.html",@path_proj + @separator+'src' + @separator+'index.html')
      FileUtils.cp("modules/LAMP/info.php",@path_proj + @separator+'src' + @separator+'info.php')
    end
    append_default
  end

  def append_default
    @file_manifest = @path_proj_puppet + @separator+'manifests' + @separator  + @name_vm.to_s + '.pp'
    to_append = File.read("modules/LAMP/default.txt")
    puts File.zero?(@file_manifest)
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
