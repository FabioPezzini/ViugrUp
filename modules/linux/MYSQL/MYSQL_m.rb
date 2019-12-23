require 'fileutils'

class MySQL
  def initialize(pro_name,name_vm)
    @path_proj = $path_folder + '/' + pro_name.to_s
    @path_proj_puppet = $path_folder + '/' + pro_name.to_s + '/puppet'
    @name_vm = name_vm
    install_stdlib
  end

  def install_stdlib
    @path_proj_stdlib = @path_proj_puppet  + '/modules/stdlib'
    value = File.exist?(@path_proj_stdlib)
    if value == false
      Dir.mkdir(@path_proj_stdlib)
      source = Dir.pwd.to_s + '/modules/linux/dependencies/stdlib'
      FileUtils.copy_entry source, @path_proj_stdlib
    end
    puts '=> Dependendency Stdlib installed in ' + @name_vm.to_s
    install_mysql
  end

  def install_mysql
    @path_proj_mysql = @path_proj_puppet  + '/modules/mysql'
    value = File.exist?(@path_proj_mysql)
    if value == false
      Dir.mkdir(@path_proj_mysql)
      source = Dir.pwd.to_s + '/modules/linux/MYSQL/mysql'
      FileUtils.copy_entry source, @path_proj_mysql
    end
    puts '==> Module MySQL installed in ' + @name_vm.to_s
    append_default
  end

  def append_default
    @file_manifest = @path_proj_puppet +'/' + @name_vm.to_s + '.pp'
    source = Dir.pwd.to_s + '/modules/linux/MYSQL/default.pp'
    value = File.exist?(@file_manifest)
    if value == true
      to_append = File.read(source.to_s)
      File.open(@file_manifest, 'a') do |handle|
        handle.puts to_append
      end
    else
      FileUtils.copy_entry source, @file_manifest
    end
    puts '=== MySQL installation completed ==='
  end
end

