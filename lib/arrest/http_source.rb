module Arrest
  class HttpSource

    def initialize base
      @base = base
    end

    def get sub
      response = self.connection().get sub 
      response.body
    end

    def put rest_resource
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id.present?
      hash = rest_resource.to_hash
      hash.delete(:id)
      hash.delete("id")

      response = self.connection().put do |req|
        req.url "#{rest_resource.class.path}/#{rest_resource.id}"
        req.headers['Content-Type'] = 'application/json'
        req.body = hash.to_json
      end
      response.env[:status] == 200
    end

    def post rest_resource
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id.present?
      hash = rest_resource.to_hash
      
      response = self.connection().post do |req|
        req.url rest_resource.class.path
        req.headers['Content-Type'] = 'application/json'
        req.body = hash.to_json
      end
      location = response.env[:response_headers][:location]
      id = location.gsub(/^.*\//, '')
      rest_resource.id= id
      response.env[:status] == 201
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
