class User < Arrest::RootResource
  attributes({
    :email => String,
    :password => String
  })
end
