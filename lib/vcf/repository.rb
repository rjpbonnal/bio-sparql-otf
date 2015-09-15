require 'rdf'
require 'vcf/reader'

module VCF
  SEQ = RDF::Vocabulary.new('http://biobeat.org/rdf/seq#')
  DB  = RDF::Vocabulary.new('http://biobeat.org/rdf/db#')

  ##
  # VCF-to-RDF repository adapter.
  class Repository < RDF::Repository
    ##
    # @param [#to_s] pathname
    def initialize(pathname)
      @reader = VCF::Reader.new(pathname)
    end

    ##
    # @return [Boolean]
    def durable?
      false
    end

    ##
    # @return [Boolean]
    def empty?
      super # TODO
    end

    ##
    # @return [Integer]
    def count
      super # TODO
    end

    ##
    # @return [Enumerator]
    def each_statement(&block)
      @reader.each_record do |record|
        record.to_rdf.each(&block)
      end
    end
    alias_method :each, :each_statement

  protected

    def query_execute(query, options = {}, &block)
      # For now, we let RDF.rb's built-in `RDF::Query#execute` handle BGP
      # query execution by breaking down the query into its constituent
      # triple patterns and invoking `RDF::Query::Pattern#execute` on each
      # pattern.
      super
    end

    def query_pattern(pattern, options = {}, &block)
      case predicate = pattern.predicate
        when RDF::URI
          case predicate
            when SEQ.chr then super # TODO
            when SEQ.pos then super # TODO
            else super # full scan for other predicates
          end
        else super # full scan for generic triple patterns
      end
    end
  end # Repository
end # VCF

if $0 == __FILE__
  require 'sparql'
  repository = VCF::Repository.new('docker/data.vcf.gz')
  SPARQL.parse("SELECT * WHERE { ?s ?p ?o }").execute(repository) do |solution|
    p solution
  end
end
