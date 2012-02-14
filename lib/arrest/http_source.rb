require 'faraday'
require 'arrest/handler'

module Arrest

  class HttpSource

    attr_reader :base

    def initialize base
      @base = base
    end

    def url
      @base
    end

    def add_headers(context,headers)
      decorator = context.header_decorator if context
      decorator ||= Arrest::Source.header_decorator
      hds = decorator.headers
      hds.each_pair do |k,v|
        headers[k.to_s] = v.to_s
      end
      hds
    end

    def get_one(context, sub, filter={})
      headers = nil
      response = self.connection().get do |req|
        req.url(sub, filter)
        headers = add_headers(context, req.headers)
      end
      rql = RequestLog.new(:get, "#{sub}#{hash_to_query filter}", nil, headers)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      if response.env[:status] != 200
        raise Errors::DocumentNotFoundError
      end
      response.body
    end

    def get_many_other_ids(context, path)
      get_one(context, path)
    end

    def get_many(context, sub, filter={})
      headers = nil
      response = self.connection().get do |req|
        req.url(sub, filter)
        headers = add_headers(context, req.headers)
      end
      rql = RequestLog.new(:get, "#{sub}#{hash_to_query filter}", nil, headers)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      response.body
    end


    def delete_all(context, resource_path)
      headers = nil
      response = self.connection().delete do |req|
        req.url(resource_path)
        headers = add_headers(context, req.headers)
      end
      rql = RequestLog.new(:delete, "#{resource_path}", nil, headers)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)

      response.env[:status] == 200
    end

    def delete(context, rest_resource)
      raise "To delete an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      headers = nil
      response = self.connection().delete do |req|
        req.url(rest_resource.resource_location)
        headers = add_headers(context, req.headers)
      end
      rql = RequestLog.new(:delete, rest_resource.resource_location, nil, headers)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      response.env[:status] == 200
    end

    def put_sub_resource(rest_resource, sub_url, ids)
      location = "#{rest_resource.resource_location}/#{sub_url}"
      body = ids.to_json

      internal_put(rest_resource, location, body)
    end

    def put(context, rest_resource)
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      hash = rest_resource.to_jhash
      insert_nulls!(rest_resource,hash)
      hash.delete(:id)
      hash.delete("id")
      body = JSON.generate(hash)

      internal_put(rest_resource, rest_resource.resource_location, body)
    end




    def internal_put(rest_resource, location, body)
      headers = nil
      response = self.connection().put do |req|
        req.url(location)
        headers = add_headers(rest_resource.context, req.headers)
        req.body = body
      end
      rql = RequestLog.new(:put, location, body, headers)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      if response.env[:status] != 200
        handle_errors(rest_resource, response.body, response.env[:status])
      end
      response.env[:status] == 200
    end

    def insert_nulls!(rest_resource, hash)
      rest_resource.class.all_fields.each do |field|
        if !field.read_only && hash[field.json_name] == nil
          hash[field.json_name] = Null.singleton
        end
      end
    end

    def post(context, rest_resource)
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id != nil
      hash = rest_resource.to_jhash
      hash.delete(:id)
      hash.delete('id')

      insert_nulls!(rest_resource,hash)

      body = JSON.generate(hash)
      headers = nil
      response = self.connection().post do |req|
        req.url rest_resource.resource_path
        headers = add_headers(context, req.headers)
        req.body = body
      end
      rql = RequestLog.new(:post, rest_resource.resource_path, body, headers)
      rsl = ResponseLog.new(response.env[:status], response.body)
      Arrest::Source.call_logger.log(rql, rsl)
      if (response.env[:status] == 201)
        location = response.env[:response_headers][:location]
        id = location.gsub(/^.*\//, '')
        rest_resource.id= id
        true
      else
        handle_errors(rest_resource, response.body, response.env[:status])
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

    private

      def handle_errors rest_resource, body, status
        err = Arrest::Source.error_handler.convert(body,status)
        if err.is_a?(String)
          rest_resource.errors.add(:base, err)
        else
          err.map do |k,v|
            if v.is_a?(String)
              rest_resource.errors.add(k,v)
            else
              v.map do |msg|
                rest_resource.errors.add(k,msg)
              end
            end
          end
        end
      end

  end
end
