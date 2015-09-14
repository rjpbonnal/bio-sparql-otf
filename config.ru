#!/usr/bin/env rackup
$:.unshift(File.expand_path('.', __dir__))

require 'lib/endpoint'

class OTF::Endpoint
  set :root, __dir__
  set :static, true
  set :public_folder, 'public'
  set :allow_origin, :any
  #set :allow_methods, [:get] #, :post, :options]
end

run OTF::Endpoint
