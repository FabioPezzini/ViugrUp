# frozen_string_literal: true
require 'colorize'
require 'rbconfig'
require 'vagrant-wrapper'

require './exceptions/not_found'

class SysManager
  def initialize
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      raise NotFound, 'OS not compatible with ViugrUp'
    else
      $path_roaming = '/opt/'
      $path_folder = $path_roaming.to_s + 'viugrup'
    end

  end

  def check_status
    puts 'Starting ViugrUp...'
    sleep(0.5)

    if check_vagrant.nil?
      raise NotFound, 'Vagrant is not installed, please install it'
    end

    if check_viugrup_folder == false
      to_print = 'INFO: A folder for your project has been created.'
      puts to_print.colorize(:light_blue)
    end
  end

  # For the first installation create a folder
  def check_viugrup_folder
    value = File.exist?($path_folder)
    Dir.mkdir($path_folder) if value == false
    value
  end

  # If Vagrant is not installed return nil
  def check_vagrant
    vw = VagrantWrapper.new
    vw.vagrant_version
  end
end