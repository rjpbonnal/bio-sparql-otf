require 'java' # requires JRuby
require 'jar/htsjdk-1.119.jar'
require 'jar/bzip2.jar'

require 'vcf/record'

module VCF
  ##
  # VCF file reader.
  #
  # This is a user-friendly wrapper for the HTSJDK implementation.
  #
  # @see https://github.com/samtools/htsjdk
  # @see https://samtools.github.io/htsjdk/javadoc/htsjdk/htsjdk/variant/vcf/VCFFileReader.html
  class Reader
    java_import 'htsjdk.variant.vcf.VCFFileReader'

    ##
    # @param [#to_s] pathname
    def self.open(pathname, &block)
      reader = self.new(pathname)
      block.call(reader)
    ensure
      #reader.close
    end

    ##
    # @param [#to_s] pathname
    def initialize(pathname)
      pathname = pathname.to_s
      @vcf_file = java.io.File.new(pathname)
      @tbi_file = java.io.File.new("#{pathname}.tbi")
      @reader = VCFFileReader.new(@vcf_file, @tbi_file, true)
    end

    ##
    # @return [Boolean]
    def closed?
      @reader.nil?
    end

    ##
    # @return [void]
    def close
      @reader.close if @reader
    ensure
      @reader, @vcf_file, @tbi_file = nil, nil, nil
    end

    ##
    # @yield  [record]
    # @yieldparam  [Record] record
    # @yieldreturn [void]
    # @return [void]
    def each_record(&block)
      return unless @reader
      @reader.iterator.each do |variant_context| # VariantContext
        record = Record.new(variant_context)
        block.call(record)
      end
    end

    ##
    # @param  [String]  chromosome
    # @param  [Integer] start_pos
    # @param  [Integer] end_pos
    # @yield  [record]
    # @yieldparam  [Record] record
    # @yieldreturn [void]
    # @return [void]
    def find_records(chromosome: nil, start_pos: nil, end_pos: nil, &block)
      return unless @reader
      start_pos  ||= 0
      end_pos    ||= java.lang.Integer::MAX_VALUE
      @reader.query(chromosome, start_pos, end_pos).each do |variant_context| # VariantContext
        record = Record.new(variant_context)
        block.call(record)
      end
    end

    ##
    # @param  [Integer] pos
    # @return [Boolean]
    def has_position?(pos)
      true # TODO
    end
  end # Reader
end # VCF

if $0 == __FILE__
  VCF::Reader.open('Homo_sapiens.vcf.gz') do |file|
    p file
    file.find_records(chromosome: "Y") do |record|
    #file.each_record do |record|
      p record
      #record.to_rdf.each do |statement|
      #  p statement
      #end
    end
  end
end
