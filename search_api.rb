#!/usr/bin/env ruby
require 'net/http'

class SearchSession
  attr_reader :response
  
  def initialize(secrets)
    @wskey = secrets['wskey_lite']
  end

  def make_request(oclcnum)
    @url = 'http://www.worldcat.org/webservices/catalog/content/' + oclcnum + '?servicelevel=full&wskey=' + @wskey
    uri = URI.parse(@url)
    request = Net::HTTP::Get.new(uri.request_uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    @response = http.start do |http| 
      http.request(request)
    end
    return @response
  end
  
end


class SearchAPI
  attr_accessor :url
  attr_reader :response

  def get_keys(filename)
    @secrets = {}
    lines = File.read(filename).split("\n")
    lines.each { |line| @secrets[line.split(" = ")[0]] = line.split(" = ")[1].rstrip }
    return @secrets
  end
  
  def create_session(secrets=@secrets)
    @session = SearchSession.new(secrets)
  end
  
  def current_oclc(oclcnum)
    oclcnum = oclcnum.to_s
    if not @session
      create_session
    end
    @response = @session.make_request(oclcnum)
    _001 = /tag="001">([0-9]*)<\/controlfield/.match(@response.body)[1]
    return _001
  end
end
#_001 = /tag="001">([0-9]*)<\/controlfield/.match(response.body)[1]
#_019 = /019">\s*<subfield code="a">([0-9]*)</.match(response.body)[1]

#for more involved parsing of api response:
=begin
  require 'marc'
  File.write('results.xml', response.body)
  reader = MARC::XMLReader.new('results.xml')
=end
