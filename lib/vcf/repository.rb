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
    def each_statement
      super # TODO
    end
    alias_method :each, :each_statement
  end # Repository
end # VCF

if $0 == __FILE__
  # TODO
end
