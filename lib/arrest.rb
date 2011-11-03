require "arrest/version"

require "arrest/http_source"
require "arrest/mem_source"
require "arrest/abstract_resource"
require "arrest/root_resource"
require "arrest/rest_child"

module Arrest

  class Source 
  
    cattr_accessor :source

  end
  Source.source= MemSource.new

end
