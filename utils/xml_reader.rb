require 'nokogiri'

class XmlReader
  def initialize(lab)
    parent_directory = File.expand_path(".", Dir.pwd)
    if $os.to_s.eql? 'windows'
      @lab_path = parent_directory + '\\labs\\' + lab.to_s + '.xml'
    else
      @lab_path = parent_directory + '/labs/' + lab.to_s + '.xml'
    end
  end

  def scan
    file = File.read(@lab_path)
    doc = Nokogiri::XML(file)
    doc.xpath('//machine').each do |machine|
      @machine_name = machine.at_xpath('machine_name').content
      @machine_base = machine.at_xpath('machine_base').content
      @machine_version = machine.at_xpath('version').content
      @provider = machine.at_xpath('provider').content
      @public_network = machine.at_xpath('public_network').content
    end
  end


end
