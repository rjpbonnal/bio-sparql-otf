require 'java' # requires JRuby
require 'jar/htsjdk-1.119.jar'
require 'jar/bzip2.jar'

require 'rdf'

module VCF
  ##
  # VCF file record.
  #
  # This is a user-friendly wrapper for the HTSJDK implementation.
  #
  # @see https://github.com/samtools/htsjdk
  # @see https://samtools.github.io/htsjdk/javadoc/htsjdk/htsjdk/variant/variantcontext/VariantContext.html
  class Record
    java_import 'htsjdk.variant.variantcontext.VariantContext'

    ##
    # @param [VariantContext] variant_context
    def initialize(variant_context)
      @context = variant_context
    end

    ##
    # @return [String]
    def id
      @context.getID
    end

    ##
    # @return [String]
    def chromosome
      @context.getChr
    end

    ##
    # @return [RDF::Graph]
    def to_rdf
      subject = self.id.to_sym
      RDF::Graph.new do |graph|
        graph << [subject, RDF::DC.identifier, subject.to_s]
      end
    end
  end # Record
end # VCF
