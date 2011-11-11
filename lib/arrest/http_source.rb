require 'faraday'

module Arrest
  class HttpSource

    def initialize base
      @base = base
    end

    def url
      @base
    end

    def add_headers headers
      Arrest::Source.header_decorator.headers.each_pair do |k,v|
        headers[k.to_s] = v.to_s
      end
    end

    def get sub, filter={}
      response = self.connection().get do |req|
        req.url sub, filter
        add_headers req.headers
      end
      response.body
    end

    def delete rest_resource
      raise "To delete an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      response = self.connection().delete do |req|
        req.url rest_resource.resource_location
        add_headers req.headers
      end
      response.env[:status] == 200
    end

    def put rest_resource
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      hash = rest_resource.to_hash
      hash.delete(:id)
      hash.delete("id")

      response = self.connection().put do |req|
        req.url rest_resource.resource_location
        add_headers req.headers
        req.body = hash.to_json
      end
      response.env[:status] == 200
    end

    def post rest_resource
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id != nil
      hash = rest_resource.to_hash
      hash.delete(:id)
      hash.delete('id')

      hash.delete_if{|k,v| v == nil}
      
      body = hash.to_json
      response = self.connection().post do |req|
        req.url rest_resource.resource_path
        add_headers req.headers
        req.body = body
      end
      if (response.env[:status] == 201)
        location = response.env[:response_headers][:location]
        id = location.gsub(/^.*\//, '')
        rest_resource.id= id
      else
        puts "unable to create: #{response.env[:response_headers]} body: #{response.body} "
        false
      end
      
    end

    def connection
      conn = Faraday.new(:url => @base) do |builder|
        builder.request  :url_encoded
        builder.request  :json
        builder.response :logger
        builder.adapter  :net_http
      end
    end

  end
end
