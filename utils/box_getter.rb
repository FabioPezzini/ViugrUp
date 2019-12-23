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

  # Scrape VagrantCloud to retrieve box id
  def scrape(value,provider)
    if provider.to_s.casecmp('VIRTUALBOX') == 0
      url = 'https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=virtualbox&q='
    elsif  provider.to_s.casecmp('DOCKER') == 0
      url = 'https://app.vagrantup.com/boxes/search?utf8=%E2%9C%93&sort=downloads&provider=docker&q='
    end
      unparsed_page = HTTParty.get(url + value.to_s)
    parsed_page = Nokogiri.HTML(unparsed_page)
    parsed_page.css('div.col-md-5').map do |node|
      @name.push(node.at_css('h4').text.strip)
      @desc.push(node.at_css('div').text.strip)
    end
  end

  # Search box id in the txt file (images folder)
  def search_box(to_search,box_dir,provider)
    File.open(box_dir, 'r') do |f|
      f.each_line do |line|
        return line.to_s.partition(' : ').last if line.to_s.partition(' : ').first.casecmp(to_search) == 0
      end
    end
    #If it isn't in the txt, that will search in the VagrantCloud
    return search_in_cloud(to_search,provider)
  end

  # Get box id from the VagrantCloud
  def search_in_cloud(machine_base,provider)
    to_print = 'It wasn t possible to find the selected os in the `images.txt`, type the number of the alternative otherwise type no to end the search'
    puts to_print.colorize(:green)
    scrape(machine_base.to_s,provider)
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
    if @input.to_i < counter && @input.to_i >= 0
      name[@input.to_i].split(' ')[0].to_s
    else
      'nil'
    end
  end

  def get_name
    @name
  end

  def get_desc
    @desc
  end
end
