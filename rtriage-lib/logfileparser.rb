module Triage
  # Parse a single file.
  class LogFileParser
    # Helpful aliases.
    TypeError = StatefulLogParser::TypeError
    TypeFailure = StatefulLogParser::TypeFailure

    # With block calls parse immediately.
    def initialize(file, &blk)
      @lp = StatefulLogParser.new
      @file = file

      if block_given?
        parse(&blk)
      end
    end

    # Invalid unless parse() has been run.
    def totals; @lp.totals; end

    # Yield data about every test.  Returns totals.
    def parse(&blk)
      File.open(@file.to_s, 'r') {|io|
        io.each_line {|l| @lp.line(l, &blk) }
      }
      @lp.finish
      @lp.totals
    end
  end
end
