require 'fileutils'

class Apache
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
    install_apache
  end

  def install_apache
    @path_proj_apache = @path_proj_puppet  + '/modules/apache'
    value = File.exist?(@path_proj_apache)
    if value == false
      Dir.mkdir(@path_proj_apache)
      source = Dir.pwd.to_s + '/modules/linux/APACHE/apache'
      FileUtils.copy_entry source, @path_proj_apache
    end
    puts '==> Module Apache installed in ' + @name_vm.to_s
    append_default
  end

  def append_default
    @file_manifest = @path_proj_puppet +'/' + @name_vm.to_s + '.pp'
    source = Dir.pwd.to_s + '/modules/linux/APACHE/default.pp'
    value = File.exist?(@file_manifest)
    if value == true
      to_append = File.read(source.to_s)
      File.open(@file_manifest, 'a') do |handle|
        handle.puts to_append
      end
    else
      FileUtils.copy_entry source, @file_manifest
    end
    puts '=== Apache installation completed ==='
  end
end

