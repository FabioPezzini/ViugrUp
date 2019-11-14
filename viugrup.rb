#!/usr/bin/env ruby
# frozen_string_literal: true

require './cmds/create_project'
require './cmds/list_project'
require './cmds/run_project'
require './cmds/stop_project'
require './cmds/install_service'
require './utils/box_getter'
require './utils/sys_manager'
require './exceptions/wrong_command_syntax'

begin
  sys_m = SysManager.new
  sys_m.check_status

  hash_cmd = {
    'createp' => CreateProject,
    'list' => ListProject,
    'run' => RunProject,
    'stop' => StopProject,
    'installin' => InstallService
  }

  cmd = 'start'
  help = File.read('help.txt')
  while cmd != 'exit'
    print '> '
    input = gets
    cmd, *args = input.split
    puts help if cmd == 'help'
    if hash_cmd.key?(cmd)
      hash_cmd[cmd].new(args)
    elsif !cmd.to_s.include?('exit') && !cmd.to_s.include?('help')
      begin
      raise WrongCommandSyntax, 'command not found'
      rescue WrongCommandSyntax => e
        puts e.message
      end
    end
  end
rescue StandardError => e
  puts e.message
end