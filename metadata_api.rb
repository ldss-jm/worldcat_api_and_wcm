#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'nokogiri'
require 'oclc/auth'
#TODO: see if there's a better option than certified for SSL cert errors
require 'certified'
require 'marc'

#TODO get other valid http response codes

@prod_secret = File.dirname(__FILE__).to_s + '/metadata.secret'

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
    
  def make_request(url, retry_on_error=true)
    make_wskey()
    @uri = URI.parse(url)
    request = Net::HTTP::Get.new(@uri.request_uri)
    # TODO: use this accept as default, but allow other accepts
    request['accept'] = 'application/atom+xml;content="application/vnd.oclc.marc21+xml"'
    request['Authorization'] = @wskey.hmac_signature('GET', url, :principal_id => @principalid, :principal_idns => @principaldns)
    http = Net::HTTP.new(@uri.host, @uri.port)
    http.use_ssl = true
    @response = http.start do |http| 
    http.request(request)
    end
    #TODO get other valid http response codes
    if @response.code != '200' and retry_on_error
      puts 'http error, retrying'
      sleep(2)
      make_request(url, retry_on_error=false)
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
  
  def initialize(secretfile)
    secrets = get_keys(secretfile)
    @session = AuthSession.new(secrets)  
  end

  def get_keys(filename)
    secrets = {}
    lines = File.read(filename).split("\n")
    lines.each { |line| secrets[line.split(" = ")[0]] = line.split(" = ")[1].rstrip }
    return secrets
  end

  def read_bib(oclcnum, schema='LibraryOfCongress', holdingLibraryCode='MAIN')
    # TODO: no clue what holdingLibraryCode is for
    oclcnum = oclcnum.to_s
    @url = 'https://worldcat.org/bib/data/' + oclcnum + '?classificationScheme=' + schema + '&holdingLibraryCode=' + holdingLibraryCode
    @response = @session.make_request(@url)
    if @response.code != '200'
      return nil
    end
    @bib = MARC::XMLReader.new(StringIO.new(@response.body)).first
    @bib.xml=@response.body
    return @bib    
  end
  
  def test_auth()
    @session.test_auth()
  end
end

class MARC::Record
  attr_reader :xml, :elvl
  
  def xml=(xml_record)
    @xml = xml_record
  end
  
  def elvl()
    mapping = {' ' => '0', 'I' => '0.I', '1' => '1', 'L' => '1.L', '2' => '2',
               'M' => '2.M', '4' => '4', '8' => '8', 'K' => '8.K', '7' => '917',
               '3' => '923', '5' => '935', 'J' => '94J'}
    return mapping[leader[17]]
  end
end
