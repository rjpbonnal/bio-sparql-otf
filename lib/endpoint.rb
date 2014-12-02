#encoding: utf-8

# Sinatra example
#
# Call as http://localhost:4567/sparql?query=uri,
# where `uri` is the URI of a SPARQL query, or
# a URI-escaped SPARQL query, for example:
#   http://localhost:4567/?query=SELECT%20?s%20?p%20?o%20WHERE%20%7B?s%20?p%20?o%7D

#Example running.
#$ jruby endpoint.rb example.vcf.gz,Homo_sapiens.vcf.gz query_parameters.sparql config.yml
require 'rubygems'
require 'rdf'
require 'sinatra/base'
require 'sinatra/sparql'
require 'uri'
require 'haml'
require 'benchmark'
  # require 'sinatra'
require 'json'
require 'rdf/ntriples'
# require 'sparql/client'
require 'lib/otf'
require 'sinatra/cross_origin'

module OTF


# require 'multi_json'
# require 'faraday'
# require 'elasticsearch'

class Endpoint < Sinatra::Base

# configure do
  # enable :cross_origin
# # #`ifconfig | grep -w -B5 'active'| grep -o "inet .* netmask" | cut -d" " -f2 | xargs`
#   set :bind, '0.0.0.0'
  # set :port, '8080'
  # set :static, true
# end


# puts ARGV.inspect
@@pool = OTF::FilePool.new

# ARGV[0].split(',').each do |file|
#   @@pool.add file
# end


if !File.exists? "config.yml"
  exit
end

@@config = YAML.load_file("config.yml")

@@config["files"].each do |file|
  @@pool.add file
end

@@vcf_parameters = File.open(@@config["query_config"]).read

puts <<-STR
Biohackathon 2014

       松島

This is the SPARQL end point for the Variant Calling Format on file #{@@pool.files.map{|file| file[:name]}.join(',')}.
The system accepts queries from which is possible to extract parametes using an internal SPARQL query on the WHERE clause:
#{@@vcf_parameters}

Please enjoy/お楽しみください SPARQL ^_^
STR



DEBUG = false

get "/query" do
	haml :query
end

get "/sparql" do
  if params["query"]
    query = params["query"].to_s.match(/^http:/) ? RDF::Util::File.open_file(params["query"]) : ::URI.decode(params["query"].to_s)


    query = OTF::Query.normalize_prefixes(query)
    chr, start, final = OTF::Query.get_parameters(query, @@vcf_parameters)
    chr_val = chr.last.to_s
    start_val = start.last.to_s
    final_val = final.last.to_s

    repository = RDF::Graph.new

    if chr_val && start_val && final_val
      

      @@pool.readers.each do |vcf_reader|
        vcf_reader.query(chr_val, start_val.to_i, final_val.to_i).each do |vc|
          OTF::VCF.new(vc, @@config).to_rdf.each do |vcf_statement|
            repository << vcf_statement
          end
        end
      end

    end
    # cross_origin
    content_type 'application/sparql-results+json'
    # content_type :html
    solutions = SPARQL.execute(query, repository)
    solutions.to_json
  else
    settings.sparql_options.merge!(:prefixes => {
      :ssd => "http://www.w3.org/ns/sparql-service-description#",
      :void => "http://rdfs.org/ns/void#"
    })
    service_description(:repo => repository)
  end
end


post "/query" do
  if params["query"]
    query = params["query"].to_s.match(/^http:/) ? RDF::Util::File.open_file(params["query"]) : ::URI.decode(params["query"].to_s)

    chr, start, final = OTF::Query.get_parameters(query, @@vcf_parameters)
    chr_val = chr.last.to_s
    start_val = start.last.to_s
    final_val = final.last.to_s

    repository = RDF::Graph.new

    if chr_val && start_val && final_val
      

      @@pool.readers.each do |vcf_reader|
        vcf_reader.query(chr_val, start_val.to_i, final_val.to_i).each do |vc|
          OTF::VCF.new(vc, @@config).to_rdf.each do |vcf_statement|
            repository << vcf_statement
          end
        end
      end

    end


    SPARQL.execute(query, repository)
  else
    settings.sparql_options.merge!(:prefixes => {
      :ssd => "http://www.w3.org/ns/sparql-service-description#",
      :void => "http://rdfs.org/ns/void#"
    })
    service_description(:repo => repository)
  end
end



get '/' do
  settings.sparql_options.replace(:standard_prefixes => true)
  # Benchmark.bm do |x|
  #   x.report("Creating a repository:") {repository = RDF::Repository.load("uploads/gwas-rdf/gwas.rdf")}
  # end
end

end #Endpoint
end #OTF
