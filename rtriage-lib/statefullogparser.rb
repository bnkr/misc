module Triage
  # For errors in parsing the log.
  class LogError < RuntimeError; end

  # Stateful per-line output parsing, i.e you call it on every line of the
  # input not just for one file.
  class StatefulLogParser
    # Counts.
    Totals = Struct.new(:tests, :asserts, :failures, :errors)

    # An uncaught exception.
    class TypeError; end
    # An assertion failed (including exception-asserts)
    class TypeFailure; end

    # Yielded when parsing.
    Data = Struct.new(
      :type,
      # Location
      :test_name, :test_class,
      # only if :type == 'TypeError'
      :exception_class,
      :backtrace,
      :message,
      :log_line
    )

    # A Totals class.  Available after parse is finished.
    attr_reader :totals

    def initialize
      @state = StStart
      @line_num = 0
      # number of tests and assertions etc. at the end of the file
      @totals = Totals.new
      # Will store "Error|Failure" etc.
      @data = nil
      @suite_name = nil
      # see repeat_spam_check
      @repeated_spam_check = false
    end

    # Call for every line.
    def line(l, &blk)
      @line = l
      @line_num += 1
      begin
        send(STATE_TABLE[@state], &blk)
      rescue ParseAgain
        retry
      end
    end

    # Call at EOF when using the line().
    def finish
      if @state == StStart
        raise LogError, "no suite name"
      elsif @state == StSpam
        if @repeated_spam_check
          m = "could not find the start of the error information despite repeated tries"
        else
          m = "could not find the start of the error information"
        end
        raise LogError, m
      elsif @state != StEnd
        raise LogError, "file ended in bad state: #{@state}"
      end
    end

    private

    class ParseAgain < Exception; end

    # See docs of state_#{one_of_these.downcase} for what the states mean.
    states = %w{
      Start Spam End
      MessageStart
      ErrorLocation ErrorException ErrorTrace
      FailureLocation FailureTrace
      FailureAssertMessage FailureBody
      FailureExceptionMessage FailureExceptionType FailureExceptionBacktrace
    }

    STATE_TABLE = {}
    states.each {|name|
      eval "class St#{name}; end"
      eval "STATE_TABLE[St#{name}] = :state_#{name.downcase}"
    }

    #####################
    ## State Functions ##
    #####################

    def state_start
      if (m = line_matches?(/^Loaded suite (.+)/))
        @suite_name = m.to_a.at(1)
        change_state(StSpam)
      end
    end

    MessageStartBitRe = /^Finished in [0-9]+([.][0-9]+)? seconds\.$/

    # Looking for the MessageStartBitRe (the end of the test spam and the
    # start of the messages)
    def state_spam
      if line_matches?(MessageStartBitRe)
        change_state(StMessageStart)
      end
    end

    TotalsRe = /^([0-9]+) tests, ([0-9]+) assertions, ([0-9]+) failures, ([0-9]+) errors$/

    # Looking for the start of an error something like "1) Error"
    def state_messagestart(&blk)
      if (m = line_matches?(/^\s*[0-9]+\)\s*([^:]+):/))
        yield @data if @data
        @data = Data.new
        @data.log_line = @line_num
        @data.type, state =
          case m.to_a.at(1).to_s
          when 'Error' then [TypeError, StErrorLocation]
          when 'Failure' then [TypeFailure, StFailureLocation]
          else lraise("unknown test type #{@data.test_type}")
          end
        change_state(state)
      elsif line_matches?(/^\s*$/)
        # skip empty lines
      elsif (m = line_matches?(TotalsRe))
        # id @data because there might have been no matching tests.
        yield @data if @data

        subexpr = {
          :tests= => 0,
          :asserts= => 1,
          :failures= => 2,
          :errors= => 3
        }

        subexpr.each_pair {|k,v| @totals.send(k, m[v].to_i) }

        change_state(StEnd)
      else
        lwarn "expected start of error; got '#{@line.chomp}'"
        repeat_spam_check
      end
    end

    def state_re
      lraise("more data after ending totals: #{@line.chomp}")
    end

    SimpleLocationRe = /^([a-zA-Z0-9_]+)\(([^)]+)\)[:]?$/

    # The line after the "1) Error" bit for Error message types.
    def state_errorlocation
      m = @line.match(SimpleLocationRe)

      if ! m
        lwarn "expected 'test_name(TestClass)'; got '#{@line.chomp}'"
        repeat_spam_check
        return
      end

      @data.test_name = m.to_a.at(1)
      @data.test_class = m.to_a.at(2)

      change_state(StErrorException)
    end

    # For an "Error" type test failure.  We should be on the exception type and
    # message line
    def state_errorexception
      m = @line.match(/^([^:]+): (.+)$/)

      if ! m
        lwarn "expected 'Type: message'; got '#{@line.chomp}'"
        repeat_spam_check
        return
      end

      @data.exception_class = m[1]
      @data.message = m[2].to_s.strip

      change_state(StErrorTrace)
    end

    # Indented backtrace after an exception message.
    def state_errortrace
      if line_empty?
        change_state(StMessageStart)
      elsif line_matches?(/^\s+/)
        @data.backtrace ||= []
        @data.backtrace << @line.strip
      else
        # This can happen in some cases.
        @data.message << @line.strip
      end
    end

    # like "test_name(ClaseName) [function]:"
    TracedLocationRe = /^([a-zA-Z0-9_]+)\(([^)]+)\)\s*\[([^\]]+)\]:$/

    # Just like ErrorLocation except there can be a mini-backtrace on the same
    # line.
    def state_failurelocation
      if (m = line_matches?(SimpleLocationRe))
        m = m.to_a
        @data.test_name = m.at(1)
        @data.test_class = m.at(2)
        change_state(StFailureTrace)
      elsif (m = line_matches?(TracedLocationRe))
        m = m.to_a
        @data.test_name = m.at(1)
        @data.test_class = m.at(2)
        @data.backtrace = m.at(3)
        change_state(StFailureBody)
      else
        lraise("dunno: '#{@line.chomp}'")
      end
    end

    # The small backtrace at the start of a failure type error.
    def state_failuretrace
      if line_matches?(/^\s+/)
        @data.backtrace ||= []
        @data.backtrace << @line.strip
      else
        @data.backtrace[0].gsub!(/^\[/, '')
        @data.backtrace[-1].gsub!(/\]:$/, '')
        change_state(StFailureBody)
        raise ParseAgain
      end
    end

    # Either the start of a textual message (from assert failure) or the header
    # for an assert_nothing_raised bit.
    def state_failurebody
      if line_matches?(/^Exception raised:/)
        change_state(StFailureExceptionType)
      else
        @data.message ||= ''
        @data.message << @line
        change_state(StFailureAssertMessage)
      end
    end

    # A standard message.
    def state_failureassertmessage
      if line_empty?
        change_state(StMessageStart)
      else
        @data.message << @line
      end
    end

    # After the start of an exception failure:
    def state_failureexceptiontype
      if (m = line_matches?(/^Class: <([^>]+)>/))
        @data.exception_class = m[1]
        change_state(StFailureExceptionMessage)
      else
        lraise("'Class: <something>' after assert-nothing-raised header")
      end
    end

    # After Class:, we get Message <blah>.
    def state_failureexceptionmessage
      if (m = line_matches?(/^Message: <"([^"]+)">/))
        @data.message = m[1]
        change_state(StFailureExceptionBacktrace)
      else
        lraise_expected("'Message: <something>' after Class: <#{@data.exception_class}>")
      end
    end

    # Skip everything until the end of the message.
    def state_failureexceptionbacktrace
      if line_empty?
        change_state(StMessageStart)
      end
    end

    #############
    ## utility ##
    #############

    def repeat_spam_check
      lwarn "assuming we started the log summary in the wrong place"
      change_state(StSpam)
      @repeated_spam_check = true
    end

    def line_matches?(re); @line.match(re); end
    def line_empty?; line_matches?(/^\s*$/); end

    def change_state(new_state)
      @state = new_state
    end

    def lwarn(s)
      lputs "warning: #{s}", STDERR
    end

    def lputs(s, stream = STDOUT); stream.puts "#{@line_num}: #{s}"; end

    def lraise(message)
      raise LogError, "#{@state}: #{@line_num}: #{message}"
    end

    def lraise_expected(message)
      lraise("expected #{message}; got '#{@line.chomp}'")
    end
  end
end

