module Arrest
  @@logger = Logger.new('log/arrest.log')

  def self.logger
    @@logger
  end
end

