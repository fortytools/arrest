require 'faraday'
require 'arrest/handler'

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

    def get_one sub, filter={}
      response = self.connection().get do |req|
        req.url sub, filter
        add_headers req.headers
      end
      rql = RequestLog.new(:get, "#{sub}#{hash_to_query filter}", nil)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      if response.env[:status] != 200
        raise Errors::DocumentNotFoundError 
      end
      response.body
    end

    def get_many sub, filter={}
      response = self.connection().get do |req|
        req.url sub, filter
        add_headers req.headers
      end
      rql = RequestLog.new(:get, "#{sub}#{hash_to_query filter}", nil)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      response.body
    end

    def delete rest_resource
      raise "To delete an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      response = self.connection().delete do |req|
        req.url rest_resource.resource_location
        add_headers req.headers
      end
      rql = RequestLog.new(:delete, rest_resource.resource_location, nil)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      response.env[:status] == 200
    end

    def put rest_resource
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      hash = rest_resource.to_jhash
      hash.delete(:id)
      hash.delete("id")
      body = hash.to_json

      response = self.connection().put do |req|
        req.url rest_resource.resource_location
        add_headers req.headers
        req.body = body
      end
      rql = RequestLog.new(:put, rest_resource.resource_location, body)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      if response.env[:status] != 200
        err = Arrest::Source.error_handler.convert(response.body, response.env[:status])
        rest_resource.errors.add(:base, err)
      end
      response.env[:status] == 200
    end

    def post rest_resource
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id != nil
      hash = rest_resource.to_jhash
      hash.delete(:id)
      hash.delete('id')

      hash.delete_if{|k,v| v == nil}
      
      body = hash.to_json
      response = self.connection().post do |req|
        req.url rest_resource.resource_path
        add_headers req.headers
        req.body = body
      end
      rql = RequestLog.new(:post, rest_resource.resource_path, body)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      if (response.env[:status] == 201)
        location = response.env[:response_headers][:location]
        id = location.gsub(/^.*\//, '')
        rest_resource.id= id
        true
      else
        err = Arrest::Source.error_handler.convert(response.body, response.env[:status])
        rest_resource.errors.add(:base, err)
        false
      end
      
    end

    def connection
      conn = Faraday.new(:url => @base) do |builder|
        builder.request  :url_encoded
        builder.request  :json
        builder.adapter  :net_http
        builder.use Faraday::Response::Logger, Arrest::logger
      end
    end

    def hash_to_query hash
      return "" if hash.empty?
      r = ""
      c = '?'
      hash.each_pair do |k,v|
        r << c
        r << k.to_s
        r << '='
        r << v.to_s
        c = '&'
      end
      r
    end

  end
end
