#!/usr/bin/ruby
# Statefully analyse a latex .log output for errors.  This is an attempt to deal
# with the utterly stupid line-wrapping which happens in .log output.


class Parser
  NoState = 1
  GetFile = 3
  FoundFile = 4

  attr_reader :state_id
  attr_reader :working
  attr_reader :inputs
  attr_reader :io

  def initialize(io)
    @inputs = []
    @io = io
    @state_id = NoState
    @working = ''
    @bracket_level = 0
  end

  def parse
    @io.each_line {|l|
      #  puts "** Parse line: '#{l.chomp}'"
      # TODO:
      #   some redundant comparisons in the error parsing here.
      if l =~ /^LaTeX Warning:/
        parse_error(l)
      elsif l =~ /^(Overfull|UnderFull)/
        parse_box_error(l)
      else
        parse_line(l)
      end
    }
  end

  private

  # Search for files.  This is pretty hackish.  Basically it just parses
  #
  #   '(filaneme '  => regiser "filename" in the stack
  #   ')'           => pop a filename
  #
  # And hopes eveything will work out!  It gets lots of stuff wrong, due to
  # wordwrapping; mostly it appends lines if something like this happens:
  #
  #   ...partial/fillename\nSomethingElseWithoutspacesInIt
  #
  # So if the partial filename ends precisely on the end of the line then there
  # is an error.
  def parse_line(l)
    i =  0
    while i < l.length
      if @state_id == NoState
        if l[i] == ?(
          @state_id = GetFile
          @working = ''
        elsif l[i] == ?)
          @inputs.pop
        end
      elsif @state_id == GetFile
        if l[i] == ?\s
          @inputs << @working
          @working = ''
          @state_id = NoState
        elsif l[i] == ?)
          # The file ended immediately so don't add it to the stack.
          @state_id = NoState
          @working = ''
        else
          @working << l[i] if l[i] != ?\n
        end
      end

      i += 1
    end

    #  puts "=> State is now: #{@inputs.inspect}"
  end

  def parse_box_error(l)
    m = l.match(/((Overfull|Underfull) \\[hv]box) \(([0-9.]+pt).*paragraph at lines ([0-9\-]+)$/)
    file = @inputs[@inputs.length - 1]
    lines = m[4]
    msg = m[1].downcase
    ammount = m[3]

    puts "#{file} #{lines}: #{msg} by #{ammount}"
  end

  def parse_error(l)
    # TODO:
    #   I also have to handle a long (80 chrs) line here because various bits of
    #   it can wrap.

    return if l =~ /LaTeX Warning: There were undefined references\./

    file = @inputs[@inputs.length - 1]
    if l =~ /Reference `([a-z:.\-0-9A-Z]+)' on page ([0-9]+) undefined on input line ([0-9]+)/
      line = $~[3].dup
      ref = $~[1].dup
      puts "#{file} #{line}: undefined reference '#{ref}'"
    elsif l =~ /^LaTeX Warning: (.*) at [0-9]+ on input line ([0-9]+)\.$/
      line = $~[2]
      msg = $~[1]
      puts "#{file} #{line}: #{msg}"
    else
      puts "#{file}: #{l}"
    end
  end
end

file = ARGV.length > 0 ? File.new(ARGV[0]) : $stdin
p = Parser.new(file)
p.parse
