require 'java'
require 'lib/jar/htsjdk-1.119.jar' #http://sourceforge.net/projects/picard/files/latest/download?source=files
require 'lib/jar/bzip2.jar' #wget http://www.kohsuke.org/bzip2/bzip2.jar
require 'lib/jar/jdbm-2.4.jar' #https://jdbm2.googlecode.com/files/jdbm-2.4.jar
require 'digest'
require 'yaml'
require 'lib/otf/vcf'

java_import "htsjdk.variant.vcf.VCFFileReader"
java_import "htsjdk.variant.variantcontext.VariantContext"

module OTF
  class FilePool
    def initialize
      @pool = []
    end

    def add(file)
      a = java.io.File.new(file)
      b = java.io.File.new("#{file}.tbi")
      @pool << {
                name: file,
                vcf:a,
                idx:b,
                reader:VCFFileReader.new(a, b, true)
              }
    end

    def files
      @pool
    end

    def readers
      @pool.map do |drop|
        drop[:reader]
      end
    end
  end#FilePool

  module Query

    def self.normalize_prefixes(query)
      prefixes =<<-PREF
prefix ensembl: <http://rdf.ebi.ac.uk/resource/ensembl/>
prefix faldo: <http://biohackathon.org/resource/faldo#>
prefix taxon: <http://identifiers.org/taxonomy/>
prefix skos: <http://www.w3.org/2004/02/skos/core#>
prefix ensemblvariation: <http://rdf.ebi.ac.uk/terms/ensemblvariation/>
prefix dc: <http://purl.org/dc/terms/>
prefix exon: <http://rdf.ebi.ac.uk/resource/ensembl.exon/>
prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
prefix transcript: <http://rdf.ebi.ac.uk/resource/ensembl.transcript/>
prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>
prefix identifiers: <http://identifiers.org/>
prefix obo: <http://purl.obolibrary.org/obo/>
prefix sio: <http://semanticscience.org/resource/>
prefix term: <http://rdf.ebi.ac.uk/terms/ensembl/>
prefix protein: <http://rdf.ebi.ac.uk/resource/ensembl.protein/>
prefix vcf: <http://rdf.ebi.ac.uk/terms/ensemblvariation/vcf/>
PREF
    prefixes + "\n" + query 
    end

    def self.normalize_filters(query)
      # Probably is better to analyze the incoming query, parsed as a SPARQL and extract from there the
      # data we need to construct the new query
  
      # puts [:fun=>"normalize_filters", :query=> query].inspect
      query = query.gsub(/FILTER.?\(.*\)/) do |s| 
        puts s
        variable, filter, value = s.gsub(/FILTER.?\(/,'').gsub(/\)/,'').split
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
        # puts "-------------------------------"
        "#{variable} #{filter} #{value} ."
      end
      # puts [:fun=>"normalize_filters", :query_normalized=> query].inspect
      query
    end

    def self.where_graph(query)
      vary_diz = Hash.new{|h,k| h[k] = SecureRandom.hex }

      pre_parse = RDF::Graph.new

      query_normalized = normalize_filters(query)
# puts [:fun=>"where_graph", :query=>query]

# [83] pry(main)> q.operands[1].class
# => SPARQL::Algebra::Operator::Project
# [84] pry(main)> q.operands[1].operands[1].class
# => SPARQL::Algebra::Operator::Filter
# [85] pry(main)> q.operands[1].operands[1].operands[1].class
# => RDF::Query
# puts [:fun=>"where_graph", :query_normalized=>query_normalized] #, :parsed=>SPARQL::Grammar.parse(query_normalized)].inspect
      query_algebra = SPARQL::Grammar.parse(query_normalized)
      patterns = get_patterns(query_algebra)
      patterns.each do |pattern|
        if pattern.subject.variable?
          pattern.subject=RDF::URI(vary_diz[pattern.subject.to_s])
        end
        if pattern.object.variable?
          pattern.object=RDF::URI(vary_diz[pattern.object.to_s])
        end
        pre_parse << pattern
      end
      pre_parse
    end #where_graph

    def self.get_parameters(original_query, parameters_query)
      where_graph(original_query).query(SPARQL::Grammar.parse(parameters_query)).first.to_a
    end

    def self.get_patterns(query_algebra)
      if query_algebra.is_a?(RDF::Query)
        query_algebra.patterns
      elsif query_algebra.respond_to?(:operands)
        # FIXME: this is not a generally viable way to proceed:
        if operand = query_algebra.operands.last
          get_patterns(operand)
        else
          raise "unable to locate BGP in the query's algebraic form"
        end
      end
    end
  end #Query
end #OTF
