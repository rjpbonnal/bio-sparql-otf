module VCF
  class Reader
    def self.open(pathname, &block)
      reader = self.new(pathname)
      block.call(reader)
    ensure
      reader.close
    end

    def initialize(pathname)
      @pathname = pathname
    end

    def close
      # TODO
    end
  end # Reader
end # VCF
