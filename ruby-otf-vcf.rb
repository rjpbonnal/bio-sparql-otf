#!/usr/bin/env ruby

require 'java'
require 'lib/jar/htsjdk-1.119.jar' #http://sourceforge.net/projects/picard/files/latest/download?source=files
require 'lib/jar/bzip2.jar' #wget http://www.kohsuke.org/bzip2/bzip2.jar
require 'rdf'
require 'rdf/ntriples'
require 'sparql'
require 'securerandom'
require 'digest'
require 'yaml'

module OTF

    class VCF

        def initialize(vcf,config)
            @vcf = vcf
						@config = config
        end

        def to_rdf
					refBaseURI = "http://rdf.ebi.ac.uk/resource/ensembl/#{@config['ensemblVersion']}/chromosome:#{@config['assemblyVersion']}:#{@vcf.getChr}"
					varBaseURI = "http://rdf.ebi.ac.uk/terms/ensemblvariation"
					vcf_rdf = []
					varURI = nil
					varID = nil
					case @vcf.getID
						when "." 
							varID = Digest::MD5.hexdigest("#{@config["species"]}:#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}")
							varURI = "#{varBaseURI}/#{varID}"
						else 
							varID = @vcf.getID
							varURI = "#{varBaseURI}/#{varID}"
							vcf_rdf << [varURI,"dc:identifier",@vcf.getID]
							vcf_rdf << [varURI,"rdfs:label",@vcf.getID]
					end
					vcf_rdf << [RDF::URI.new(refBaseURI),"dc:identifier","#{@vcf.getChr}"]
					faldoRegion = RDF::URI.new(refBaseURI+":#{@vcf.getStart}-#{@vcf.getEnd}:1")
					vcf_rdf << [RDF::URI.new(varURI),"faldo:location",faldoRegion]
					vcf_rdf << [faldoRegion,"rdfs:label","#{@vcf.getChr}:#{@vcf.getStart}-#{@vcf.getEnd}:1"]
					vcf_rdf << [faldoRegion,"rdf:type","faldo:Region"]
					vcf_rdf << [faldoRegion,"faldo:begin",RDF::URI.new(refBaseURI+":#{@vcf.getStart}:1")]
					vcf_rdf << [faldoRegion,"faldo:end",RDF::URI.new(refBaseURI+":#{@vcf.getEnd}:1")]
					vcf_rdf << [faldoRegion,"faldo:reference",refBaseURI]
					if @vcf.getStart == @vcf.getEnd
       			faldoExactPosition = RDF::URI.new(refBaseURI+":#{@vcf.getStart}:1")
						vcf_rdf << [faldoExactPosition,"rdf:type","faldo:ExactPosition"]
						vcf_rdf << [faldoExactPosition,"rdf:type","faldo:ForwardStrandPosition"]
						vcf_rdf << [faldoExactPosition,"faldo:position",@vcf.getStart]
						vcf_rdf << [faldoExactPosition,"faldo:reference",refBaseURI]
       		end
					refAllele = @vcf.getReference.getBaseString
					refAlleleURI = RDF::URI.new(varURI+"\##{refAllele}")
					vcf_rdf << [RDF::URI.new(varURI),RDF::URI.new(varURI+":has_allele"),refAlleleURI]
					vcf_rdf << [refAlleleURI,"rdfs:label","#{varID} allele #{refAllele}"] 
					vcf_rdf << [refAlleleURI,"a",RDF::URI.new(varURI+":reference_allele")] 
					altAllele = @vcf.getAlternateAlleles.first.getBaseString
					altAlleleURI = RDF::URI.new(varURI+"\##{altAllele}")
					vcf_rdf << [varURI,RDF::URI.new(varURI+":has_allele"),altAlleleURI]
					vcf_rdf << [altAlleleURI,"rdfs:label","#{varID} allele #{altAllele}"] 
					vcf_rdf << [altAlleleURI,"a",RDF::URI.new(varURI+":ancestral_allele")] 
				end
    end

    module Query

      def self.normalize_filters(query)
        query.gsub(/FILTER(.*)\./) do |s| 
          variable, filter, value = s.gsub(/FILTER\(/,'').gsub(/\)/,'').split
          filter = "<filter_by>"
          # case filter
          # when '>'
          #   "value_gt"
          # when '<'
          #   "value_lt"
          # when '='
          #   "value_equal"
          # when '>='
          #   "value_get"
          # when '<='
          #   "value_let"
          # end
          "#{variable} #{filter} #{value} ."
        end
      end

    end

end

java_import "htsjdk.variant.vcf.VCFFileReader"
java_import "htsjdk.variant.variantcontext.VariantContext"

file_name = ARGV[0]
query = File.open(ARGV[1]).read
config = YAML.load_file(ARGV[3])

file = java.io.File.new(ARGV[0])
fileidx = java.io.File.new("#{ARGV[0]}.tbi")
vcf = VCFFileReader.new(file, fileidx, true)

triplets = []
chr = nil
start = nil
stop = nil

vary_diz = Hash.new{|h,k| h[k] = SecureRandom.hex }

pre_parse = RDF::Graph.new

puts "Original Query"
puts query

query = OTF::Query.normalize_filters(query)

puts "Normalized Query"
puts query

SPARQL::Grammar.parse(query).operands[1].patterns.each do |pattern|
  if pattern.subject.variable?
    pattern.subject=RDF::URI(vary_diz[pattern.subject.to_s])
  end
  if pattern.object.variable?
    pattern.object=RDF::URI(vary_diz[pattern.object.to_s])
  end
  # puts pattern.to_s
  pre_parse << pattern
end

vcf_parameters = File.open(ARGV[2]).read
                 # "select ?s where { ?s <location> ?location . ?s <reference> [ <identifer> "1" ] . ?location <begin> [ <position> 5 ] . ?location <end> [ <position> 20 ] . }"
# SPARQL.execute(vcf_parameters, pre_parse, options={})

chr, start, final = pre_parse.query(SPARQL::Grammar.parse(vcf_parameters)).first.to_a

puts chr
puts start
puts final

chr_val = chr.last.to_s
start_val = start.last.to_s
final_val = final.last.to_s

repository = RDF::Graph.new

if chr_val && start_val && final_val
  vcf.query(chr_val, start_val.to_i, final_val.to_i).each do |vc|
    OTF::VCF.new(vc,config).to_rdf.each do |vcf_statement|
      # repository << vcf_statement
      puts vcf_statement.inspect
    end
  end
end

# repository.graphs.enum_triple do |t|
#   puts t
# end
 #SPARQL.execute(query, repository, options={})
