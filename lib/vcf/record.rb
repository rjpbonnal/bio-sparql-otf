require 'java' # requires JRuby
require 'jar/htsjdk-1.119.jar'
require 'jar/bzip2.jar'

require 'digest/md5'
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

    FALDO = RDF::Vocabulary.new("http://biohackathon.org/resource/faldo#")

    REF_BASE_URI = 'http://rdf.ebi.ac.uk/resource/ensembl/%s/chromosome:%s:%s'.freeze
    VAR_BASE_URI = 'http://rdf.ebi.ac.uk/terms/ensemblvariation/%s'.freeze

    ##
    # @param [VariantContext] variant_context
    def initialize(variant_context)
      @vcf = variant_context
    end

    ##
    # @return [String]
    def id
      @id ||= case (id = @vcf.getID)
        when '.'
          label = "%s:%s:%s-%s" % ['', @vcf.getChr, @vcf.getStart, @vcf.getEnd] # TODO: species
          ::Digest::MD5.hexdigest(label)
        else id
      end
    end

    ##
    # @return [String]
    def uri
      @uri ||= VAR_BASE_URI % self.id
    end

    ##
    # @return [String]
    def chromosome
      @vcf.getChr
    end

    ##
    # @return [Hash{String => String}]
    def attributes
      @vcf.getAttributes
    end

    ##
    # @return [RDF::Graph]
    def to_rdf
      subject = RDF::URI(self.uri)
      RDF::Graph.new do |graph|
        graph << [subject, RDF::DC.identifier, self.id]
        graph << [subject, RDF::RDFS.label, self.id]
        @vcf.attributes.each do |k, v|
          graph << [subject, RDF::URI(VAR_BASE_URI % "vcf/attribute\##{k}"), v] if v
        end
        # TODO
      end
    end
  end # Record
end # VCF
