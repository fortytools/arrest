class User < Arrest::RootResource
  attribute :email, String
  attribute :password, String
end
