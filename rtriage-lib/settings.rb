module Triage
  # Container for settings and parser of cli.
  class Settings
    attr_reader :log_file
    attr_reader :state_file

    def initialize
      @state_file = nil
    end

    # Parse and mauybe exit.
    def parse!(args)
      p = make_parser
      files = p.parse(args)

      if files.empty?
        exit_fail "no input files"
      elsif files.length > 1
        exit_fail "only one file is allowed"
      end

      files.each {|f|
        f = Pathname.new(f)
        if ! f.exist?
          exit_fail "file #{f} does not exist"
        elsif f.directory?
          exit_fail "file #{f} is a directory"
        end

        @log_file = f.realpath
      }

      if @state_file == nil
        default = Pathname.pwd + "./rtriage.yaml"
        if default.exist? && ! default.directory?
          @state_file = default
        else
          exit_fail "no --state and no default state file found (rtriage.yaml in pwd)"
        end
      end

      self
    end

    private

    def exit_fail(message)
      STDERR.puts "triage: #{message}"
      Kernel.exit 1
    end

    def make_parser
      op = OptionParser.new
      op.banner += " log\n"
      op.banner += "Parse log file, display a nice report, and keep persistant data about tests."

      op.separator "\nOptions:"
      op.on("-h", "--help", "This message") {
        puts op
        Kernel.exit 0
      }

      op.on('-l', '--logs', "Input files are logs to be parsed (run no tests).") {
        @logs = true
      }

      msg = "Load yaml data of test results we already know about.  Default is to " +
            "load rtriage.yaml in the pwd."
      op.on('-s', '--state=FILE', msg) {|val|
        if ! File.exist?(val)
          exit_fail("--state '#{val}' does not exist")
        end
        @state_file = Pathname.new(val)
      }


      op
    end
  end
end
