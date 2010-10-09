module Triage
  # Container for settings and parser of cli.
  class Settings
    attr_reader :log_file
    attr_reader :state_file
    attr_bool_reader :update_state

    def initialize
      @state_file = nil
      @update_state = false
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
      op.banner += "Parse log file, display a nice report, and keep persistant data about tests.\n"
      op.banner += "Display options are a logical or of conditions to display on except."

      op.separator "\nOptions:"
      op.on("-h", "--help", "This message") {
        puts op
        Kernel.exit 0
      }

      msg = "Load yaml data of test results we already know about.  Default is to " +
            "load rtriage.yaml in the pwd."
      op.on('-s', '--state=FILE', msg) {|val|
        if ! File.exist?(val)
          exit_fail("--state '#{val}' does not exist")
        end
        @state_file = Pathname.new(val)
      }

      op.on("--update-state", "Modify the persistent state to respect the given log file.") {
        fail "not implemented"
      }

      op.separator "\nDisplay Options:"

      op.on('-c', '--correct', "Display tests which have become correct.") {
        fail "not implemented"
      }

      op.on("-i", '--not-implemented', "Display tests which are not implemented.") {
        fail "not implemented"
      }

      op.on("-u", '--unchanged', "Display tests which are unchanged.") {
        fail "not implemented"
      }

      op.on('--hidden', "Display tests which are explicitly marked hidden.") {
        fail "not implemented"
      }

      op.on('--message', "Display tests whose error message has changed.") {
        fail "not implemented"
      }

      op.on("-k", '--unknown', "Display tests wich have not been marked known.") {
        fail "not implemented"
      }

      op.on("--all", "Display everything.") {
        fail "not implemented"
      }


      op
    end
  end
end
