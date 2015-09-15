#!/usr/bin/env rackup
$:.unshift(File.expand_path('.', File.dirname(__FILE__)))

require 'fileutils'
require 'lib/endpoint'

class OTF::Endpoint
  set :root, File.dirname(__FILE__)
  set :static, true
  set :public_folder, 'public'
  set :allow_origin, :any
  #set :allow_methods, [:get] #, :post, :options]
end

run OTF::Endpoint
