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

    puts '==> Checking Vagrant installation...'
    if check_vagrant.nil?
      raise NotFound, 'Vagrant is not installed, please install it'
    end

    if check_viugrup_folder == false
      to_print = 'INFO: A folder for your project has been created.'
      puts to_print.colorize(:light_blue)
    end

    puts '==> Checking Docker installation...'
    if check_docker_installation == false
      raise NotFound, 'Docker is not installed, please install it'
    end

    puts '==> Check if Docker is running...'
    if check_docker__not_running == true
      raise NotFound, 'Docker is not running, please run it typing `service docker start`'
    end

  end

  # For the first installation create a folder
  def check_viugrup_folder
    value = File.exist?($path_folder)
    Dir.mkdir($path_folder) if value == false
    value
  end

  # Check if docker is installed
  def check_docker_installation
    cmd = 'docker -v'
    Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
      @out = stdout.read
    end
    @out.include?"Docker version"
  end

  # Check if docker is running
  def check_docker__not_running
    cmd = 'docker ps'
    Open3.popen3(cmd) do |_stdin, _stdout, stderr, _wait_thr|
      @out = stderr.read
    end
    @out.include?"Cannot connect to the Docker daemon"
  end


  # If Vagrant is not installed return nil
  def check_vagrant
    vw = VagrantWrapper.new
    vw.vagrant_version
  end
end