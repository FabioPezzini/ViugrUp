# frozen_string_literal: true

require 'nokogiri'
require 'httparty'
require 'colorize'
require 'fileutils'

class BoxGetter
  def initialize
    @name = Array[]
    @desc = Array[]
  end

  def scrape(value)
    url = 'https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=virtualbox&q='
    unparsed_page = HTTParty.get(url + value.to_s)
    parsed_page = Nokogiri.HTML(unparsed_page)
    parsed_page.css('div.col-md-5').map do |node|
      @name.push(node.at_css('h4').text.strip)
      @desc.push(node.at_css('div').text.strip)
    end
  end

  def search_box(machine_base,machine_version,box_dir)
    to_search = machine_base.to_s + machine_version.to_s
    File.open(box_dir, 'r') do |f|
      f.each_line do |line|
        return line.to_s.partition(': ').last if line.match(/^#{to_search}/)
      end
    end
    #If it isn't in the txt, that will search in the Vagrant cloud
    return search_in_cloud(machine_base)
  end

  def search_in_cloud(machine_base)
    to_print = 'It wasn t possible to find the selected os in the `boxes.txt`, type the number of the alternative otherwise type no to end the search'
    puts to_print.colorize(:green)
    scrape(machine_base.to_s)
    name = @name
    desc = @desc
    counter = 0
    name.each do |x|
      puts '[SELECT NUM]' + "\t\t\t" + '[BOX NAME]' + "\t\t\t\t" + '[DESCRIPTION]'
      puts counter.to_s + "\t\t\t" + x.split(' ')[0].to_s + "\t\t" + desc[counter].to_s
      counter += 1
    end
    print 'Insert number of choosen OS:'
    @input = gets
    if @input.to_i <= counter && @input.to_i >= 0
      name[@input.to_i].split(' ')[0].to_s
    else
      raise NotFound, 'No OS is selected, correct the scenario and retry'
    end
  end

  def get_name
    @name
  end

  def get_desc
    @desc
  end
end
