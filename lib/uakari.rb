require 'httparty'
require 'json'
require 'cgi'

class Uakari
  include HTTParty
  default_timeout 30

  attr_accessor :apikey, :timeout

  def initialize(apikey = nil, extra_params = {})
    @apikey = apikey
    @default_params = {:apikey => apikey}.merge(extra_params)
  end

  def apikey=(value)
    @apikey = value
    @default_params = @default_params.merge({:apikey => @apikey})
  end

  def base_api_url
    dc = @apikey.blank? ? '' : "#{@apikey.split("-").last}."
    "https://#{dc}sts.mailchimp.com/1.0/"
  end

  def call(method, params = {})
    url = "#{base_api_url}#{method}"
    params = @default_params.merge(params)
    params.each_pair {|k,v| params[k] = CGI::escape(v) if v.class == String}
    response = self.class.post(url, :body => params, :timeout => @timeout)

    begin
      response = JSON.parse(response.body)
    rescue
      response = response.body
    end
    response
  end

  def method_missing(method, *args)
    method = method.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase } #Thanks for the gsub, Rails
    args = {} unless args.length > 0
    args = args[0] if (args.class.to_s == "Array")
    call(method, args)
  end
end