class ProjectStatus
  def initialize; end

  # Method that return the status of the machines in a specific project
  # return 1 -> running , 0 -> poweroff, -1 -> not created
  def project_status(path_to_folder)
    value = -1
    cmd = 'cd ' + $path_folder + '/'+ path_to_folder.to_s + ';' + ' vagrant status'
    Open3.popen3(cmd) do |_stdin, stdout, _stderr, _wait_thr|
      out = stdout.read
      if out.include? 'running'
        value = 1
      end
      if out.include? 'not created'
        value = -1
      end
      if out.include? 'poweroff'
        value = 0
      end
      if out.include? 'stopped'
        value = 0
      end
    end
    value
  end
end
