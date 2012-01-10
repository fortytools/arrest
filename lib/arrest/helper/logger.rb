module Arrest
  unless File::directory?( "log" )
    Dir.mkdir("log")
  end
  @@logger = Logger.new('log/arrest.log')

  def self.logger
    @@logger
  end
end

