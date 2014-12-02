require 'lib/endpoint'
class OTF::Endpoint
  set :static, true
  set :public, "public"
  set :allow_origin, :any
  #set :allow_methods, [:get] #, :post, :options]
end

run OTF::Endpoint