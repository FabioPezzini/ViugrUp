# frozen_string_literal: true

require 'nokogiri'
require 'httparty'

class BoxGetter
  def initialize(value)
    @name = Array[]
    @desc = Array[]
    scrape(value)
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

  def get_name
    @name
  end

  def get_desc
    @desc
  end
end
