require 'rdf'
require 'vcf/reader'

module VCF
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
  end # Repository
end # VCF

if $0 == __FILE__
  repository = VCF::Repository.new('Homo_sapiens.vcf.gz')
  repository.each_statement do |statement|
    p statement
  end
end
