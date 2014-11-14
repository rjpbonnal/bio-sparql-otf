#!/usr/bin/env ruby

#encoding: utf-8

# Sinatra example
#
# Call as http://localhost:4567/sparql?query=uri,
# where `uri` is the URI of a SPARQL query, or
# a URI-escaped SPARQL query, for example:
#   http://localhost:4567/?query=SELECT%20?s%20?p%20?o%20WHERE%20%7B?s%20?p%20?o%7D
require 'rubygems'
require 'rdf'
require 'sinatra'
require 'sinatra/sparql'
require 'uri'
require 'haml'
require 'benchmark'
# require 'multi_json'
# require 'faraday'
# require 'elasticsearch'
require 'json'
require 'rdf/ntriples'
require 'sparql/client'
require 'lib/otf'

#`ifconfig | grep -w -B5 'active'| grep -o "inet .* netmask" | cut -d" " -f2 | xargs`
set :bind, '0.0.0.0'
set :port, '8080'

puts ARGV.inspect
@@file = java.io.File.new(ARGV[0])
@@fileidx = java.io.File.new("#{ARGV[0]}.tbi")
@@vcf = VCFFileReader.new(@@file, @@fileidx, true)
@@vcf_parameters = File.open(ARGV[1]).read
@@config = YAML.load_file(ARGV[2])

puts <<-STR
Biohackathon 2014

       松島

This is the SPARQL end point for the Variant Calling Format on file #{@@file}.
The system accepts queries from which is possible to extract parametes using an internal SPARQL query on the WHERE clause:
#{@@vcf_parameters}

Please enjoy/お楽しみください SPARQL ^_^
STR



DEBUG = false

get "/query" do
	haml :query
end

# get "/sparql" do #to make the query federable from virtuoso
#   if params["query"]
#     query = params["query"].to_s.match(/^http:/) ? RDF::Util::File.open_file(params["query"]) : ::URI.decode(params["query"].to_s)
#     options = {:ref_db => :ensembl, :ref_db_version => 75, :species => 'homo_sapiens'}
#     local_gene = "http://genome.db/#{options[:ref_db]}/#{options[:ref_db_version]}/#{options[:species]}/"
#     sparql_logic(query) do |results|
#       triplette = []
#       results["hits"]["hits"].each do |hits|
#         hit = hits["_source"]
#         if hit.key?('file_type')
#           hit["tags"].each do |tag|
#             if hit.key?(tag)
#               uri = RDF::URI("#{local_gene}#{hit['parent']}/#{tag}/#{gene}")
#               triplette << [ uri, RDF::URI("efo:EFO_0000001"), tag ]
#               triplette << [ uri, RDF::URI("http://genome.db/analysis/has_gene_id"), gene ]
#               triplette << [ uri, RDF::URI("http://genome.db/analysis/is_a"), hit['file_type'] ]
#               triplette << [ uri, RDF::URI("http://genome.db/analysis/has_fpkm"), hit[tag] ]
#       #add connection with ensmbl human_75 ttl created and RDF Summit
#               triplette << [ RDF::URI("http://rdf.ebi.ac.uk/resource/ensembl/#{gene}"), RDF::URI("http://genome.db/analysis/has_analysis"), uri ]
#             end
#           end
#         else
#           uri = RDF::URI("#{local_gene}#{hit['parent']}/#{hit['gene_id']}")
#           triplette << [ uri, RDF::URI("http://genome.db/analysis/has_gene_id"), hit["gene_id"] ]
#           triplette << [ uri, RDF::URI("http://genome.db/analysis/has_fpkm"), hit['FPKM'] ] if hit.key?('FPKM')
#           triplette << [ uri, RDF::URI("http://genome.db/analysis/has_fpkm_conf_lo"), hit['FPKM_conf_lo'] ] if hit.key?('FPKM_conf_lo')
#           triplette << [ uri, RDF::URI("http://genome.db/analysis/has_fpkm_conf_hi"), hit['FPKM_conf_hi'] ] if hit.key?('FPKM_conf_hi')
#           triplette << [ uri, RDF::URI("http://genome.db/analysis/has_fpkm_status"), hit['FPKM_status'] ] if hit.key?('FPKM_status')
#       #add connection with ensmbl human_75 ttl created and RDF Summit
#           triplette << [ RDF::URI("http://rdf.ebi.ac.uk/resource/ensembl/#{hit['gene_id']}"), RDF::URI("http://genome.db/analysis/has_analysis"), uri ]
#         end #if file type
#       end #results hits
#       triplette
#     end #sparql_logic
#   else
#     settings.sparql_options.merge!(:prefixes => {
#       :ssd => "http://www.w3.org/ns/sparql-service-description#",
#       :void => "http://rdfs.org/ns/void#"
#     })
#     service_description(:repo => repository)
#   end
# end

post "/query" do
  if params["query"]
    query = params["query"].to_s.match(/^http:/) ? RDF::Util::File.open_file(params["query"]) : ::URI.decode(params["query"].to_s)

puts query
puts @@file.inspect
puts @@vcf.inspect
puts @@vcf_parameters.inspect
puts @@config.inspect

    chr, start, final = OTF::Query.get_parameters(query, @@vcf_parameters)
    puts chr_val = chr.last.to_s
    puts start_val = start.last.to_s
    puts final_val = final.last.to_s

    repository = RDF::Graph.new

    if chr_val && start_val && final_val
      

      @@vcf.query(chr_val, start_val.to_i, final_val.to_i).each do |vc|
        OTF::VCF.new(vc, @@config).to_rdf.each do |vcf_statement|
          # puts vcf_statement.inspect
            repository << vcf_statement
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
