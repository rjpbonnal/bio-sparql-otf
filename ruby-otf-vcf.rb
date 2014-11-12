
require 'java'
require 'lib/jar/htsjdk-1.119.jar' #http://sourceforge.net/projects/picard/files/latest/download?source=files
require 'lib/jar/bzip2.jar' #wget http://www.kohsuke.org/bzip2/bzip2.jar
require 'rdf'
require 'rdf/ntriples'
require 'sparql'
require 'securerandom'

module OTF

    class VCF

        def initialize(vcf)
            @vcf = vcf
        end

        def to_rdf
#deve ritornare un array piatto

          vcf_rdf = [[RDF::URI("<On>"), RDF::URI("<The>"), RDF::URI("#{@vcf.getID}")]]

          # vcf_rdf.flatten(1)
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
    OTF::VCF.new(vc).to_rdf.each do |vcf_statement|
      # repository << vcf_statement
      puts vcf_statement.inspect
    end
  end
end

# repository.graphs.enum_triple do |t|
#   puts t
# end
# SPARQL.execute(query, repository, options={})