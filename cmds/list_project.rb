require './utils/vagrantfile_reader'

class ListProject
  def initialize(args)
    parse_args(args)
  end

  def parse_args(args)
    begin
      if %w[-up -all].include?args[0]
        parse_flag(args)
      else
        raise WrongCommandSyntax, 'No existing flag for the command'
      end
    end
  rescue WrongCommandSyntax => e
    puts e.message
  end

  def parse_flag(args)
    list_all if args[0] == '-all'
    list_active if args[0] == '-up'
  end

  def list_all
    puts 'SlinkyEnv'
    projects = Dir.entries($path_folder).reject { |f| File.directory?(f) || f[0].include?('.') }
    projects.each do |x|
      output_status(x)
    end
  end

  def list_active
    puts 'SlinkyEnv - Running...'

    projects = Dir.entries($path_folder).reject { |f| File.directory?(f) || f[0].include?('.') }
    projects.each do |x|
      output_status(x) if project_is_up(x.to_s)
    end
  end

  def output_status(x)
    v_reader = VagrantFileReader.new(x)
    v_reader.read
    print '|__'
    puts x.to_s
    hostname = v_reader.get_hostname
    box = v_reader.get_box
    count = 0
    hostname.each do |host|
      print '|'
      print '     |__' + ' Hostname:' + host.to_s + "\t"
      print 'Box:' + box[count].to_s
      count += 1
      puts ''
    end
  end

  def project_is_up(folder)
    value = false
    if $os.to_s.eql? 'windows'
      path = $path_folder + '\\' + folder.to_s
      cmd = 'powershell.exe cd ' + path.to_s + ';' + ' vagrant status'
    else
      path = $path_folder + '/' + folder.to_s
      cmd = 'cd ' + path.to_s + ';' + ' vagrant status'

    end
    Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
      out = stdout.read
      value = true if out.include? 'running'
    end
    value
  end
end