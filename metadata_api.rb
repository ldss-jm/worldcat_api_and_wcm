#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'nokogiri'
require 'oclc/auth'
#TODO: see if there's a better option than certified for SSL cert errors
require 'certified'

class AuthSession
attr_reader :response

  def initialize(secrets)
    @key = secrets['key']
    @secret = secrets['secret']
    @principalid = secrets['principalid']
    @principaldns = secrets['principaldns']
    @instsymbol = secrets['instSymbol']
  end
  
  def make_wskey()
    @wskey = OCLC::Auth::WSKey.new(@key, @secret)
  end
    
  def make_request(url)
    make_wskey()
    @uri = URI.parse(url)
    request = Net::HTTP::Get.new(@uri.request_uri)
    request['Authorization'] = @wskey.hmac_signature('GET', url, :principal_id => @principalid, :principal_idns => @principaldns)
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = true
    @response = http.start do |http| 
    http.request(request)
    end
    return @response
  end

  def test_auth()
    url = 'https://worldcat.org/bib/data/46394151?classificationScheme=LibraryOfCongress&holdingLibraryCode=MAIN'
    status = make_request(url).code
    if status == '200'
      puts 'Authentication successful.'
      return true
    else
      puts 'Test authentication failed. Wrong credentials or ' +
           'worldcat service down?'
      return false
    end
  end

end

class MetadataAPI
  attr_accessor :url
  attr_reader :response, :bib

  def get_keys(filename)
    @secrets = {}
    lines = File.read(filename).split("\n")
    lines.each { |line| @secrets[line.split(" = ")[0]] = line.split(" = ")[1].rstrip }
    return @secrets
  end

  def create_session(secrets=@secrets)
    @session = AuthSession.new(secrets)
  end

  def read_bib(oclcnum, schema='LibraryOfCongress', holdingLibraryCode='MAIN')
    # TODO: no clue what holdingLibraryCode is for
    oclcnum = oclcnum.to_s
    @url = 'https://worldcat.org/bib/data/' + oclcnum + '?classificationScheme=' + schema + '&holdingLibraryCode=' + holdingLibraryCode
    if not @session
      create_session
    end
    @response = @session.make_request(@url)
    @bib = parse_bib(@response)
  end

  def parse_bib(response=@response)
    doc = Nokogiri::XML(response.body)
    record = JSON.parse(doc.xpath('//xmlns:content').text)['record']
    # record keys: fixedFields, variableFields, adminData
    fields={}
    record['fixedFields'].each do |field|
      if fields.include?(field['tag'])
        fields[field['tag']] << field
      else
        fields[field['tag']] = [field]
      end
    end
    record['variableFields'].each do |field|
      if fields.include?(field['tag'])
        fields[field['tag']] << field
      else
        fields[field['tag']] = [field]
      end
    end
    return fields
  end
  
  def test_auth()
    @session || create_session
    @session.test_auth()
  end
end
