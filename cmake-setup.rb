#!/usr/bin/ruby -w
require 'pathname'
require 'fileutils'

CMAKE_CMD     = "cmake"
WIN_TOOLCHAIN = Pathname.new("/home/bunker/src/cross/win/toolchain-windows.cmake");
DEFAULT_ARGS  = ['-Wdev', '-GUnix Makefiles', '-DCMAKE_BUILD_TYPE=Debug']

if not WIN_TOOLCHAIN.readable?
  STDERR.puts "error: can't read the windows toolchain file '#{WIN_TOOLCHAIN}'."
end

def run_initial_command(args, name)
  cmd = CMAKE_CMD

  puts "#{cmd} #{args.join(' ')}"
  system(cmd, *args)

  if not $?.success?
    STDERR.puts "cmake-setup.rb: error: failed to set up #{name}."
    Kernel.exit($?.exitstatus)
  end
end

# ensure this is a cmake dir and remove if necessary.  Will refuse to remove
# if the dir is not unix or win unless the bindir parameter is given.
def checked_remove(bindir = nil)
  puts "Cleaning bindir"
  if bindir
    d = Pathname.new(bindir)
    return if not d.exist?

    check = d + "./CMakeCache.txt"
    if not check.exist?
      raise "-c used but the dir '#{d}' does not appear to be a cmake binary dir - remove manually, please."
    end

    puts "rm -rf #{d}"
    FileUtils.rm_rf(d)
  else
    raise "refusing to remove the dir which we are in"
  end
end

# Returns a list of args formatted for cmake binary
def process_extra_defines(v)
  r = []
  v.each {|d| r << "-D#{d}" }
  r
end

# Must be inside the correct bindir
def setup_unix(srcdir, extra_defines = [])
  args = DEFAULT_ARGS.dup
  args += process_extra_defines(extra_defines)
  args << srcdir
  run_initial_command(args, "unix")
end

# Must be inside the correct bindir
def setup_win(srcdir, extra_defines = [])
  args = DEFAULT_ARGS.dup
  args << "-DCMAKE_TOOLCHAIN_FILE=#{WIN_TOOLCHAIN}"
  args += process_extra_defines(extra_defines)
  args << srcdir
  run_initial_command(args, "win32")

  build_aux = Pathname.new("#{ARGV[0]}/build-aux/")
  if not build_aux.directory?
    STDERR.puts "cmake-setup.rb: warning: no srcdir/build-aux directory - are you sure you don't need windows DLLs?"
  else
    num = 0
    Dir.open(build_aux).each {|f|
      if f =~ /\.dll$/
        num += 1
        # NOT realpath
        FileUtils.ln_s(Pathname.new("#{build_aux}/#{f}").cleanpath, "./", {:verbose => true})
      end
    }

    if num == 0
      STDERR.puts "cmake-setup.rb: notice: no DLLs found in #{build_aux}.  Are you sure you don't need any for a windows build?"
    end
  end
end

# If bindir is nul then no subdir is made.  The block should call setup_win or setup_unix.
def do_create(bindir, &block)
  if bindir != nil
    if (! Pathname.new(bindir).directory?)
      FileUtils.mkdir(bindir, {:verbose => true})
    end
    ok = Dir.chdir(bindir)
    if (! ok)
      STDERR.puts "cmake-setup.rb: error: couldn't change to bin dir '#{bindir}'"
      Kernel.exit(1)
    end
  end

  block.call

  if bindir != nil
    ok = Dir.chdir("..")
    if ! ok
      STDERR.puts "cmake-setup.rb: error: couldn't change out of '#{bindir}'"
      Kernel.exit(1)
    end
  end
end


if ARGV.include?('-h')
  puts "cmake-setup.rb [OPTION]... SRCDIR"
  puts "Set up the initial cmake cache.  If no option is given, then both types are made"
  puts "in subdirectories unless we are in a directory called 'unix' or 'win'."
  puts
  puts "  -h  print this message and quit."
  puts "  -u  create unix cache."
  puts "  -w  create win32 cache."
  puts "  -c  delete the existing cache first."
  puts "  -D var=value  values to pass on to cmake cmdline as -Dvar=value."
  Kernel.exit(0);
end

dir = Pathname.new(Dir.pwd).basename.to_s
started_from_windows = started_from_unix = false
if (dir == 'win')
  started_from_windows = true
elsif dir == 'unix'
  started_from_unix = true
end

create_unix = false
create_windows = false
non_args = []
extra_defines = []
clean = false
i = 0
while i < ARGV.length
  a = ARGV[i]
  if a == '-u'
    if started_from_windows
      STDERR.puts "cmake-setup.rb: error: creating unix (-u) while in a windows dir."
      Kernel.exit(1)
    end
    create_unix = true
  elsif a == '-w'
    if started_from_unix
      STDERR.puts "cmake-setup.rb: error: creating windows (-w) while in a unix dir."
      Kernel.exit(1)
    end
    create_windows = true
  elsif a == '-d'
    i += 1
    v = ARGV[i]
    if (v && v =~ /[a-zA-Z_][a-zA-Z0-9_]*=.*/)
      extra_defines << v
    else
      STDERR.puts "Error: -d requires a var=value style argument."
      Kernel.exit(1)
    end
  elsif a == '-c'
    clean = true
  elsif a != "-h"
    non_args << a
  end
  i += 1
end

# Default to the current wd.
if (not create_unix) && (not create_windows)
  # if (File.exist?("./CMakeCache.txt"))
  create_windows = started_from_windows
  create_unix = started_from_unix
end

if (not create_unix) && (not create_windows)
  create_windows = create_unix = true
end

# Detect the srcdir if it's not given
if non_args.length == 0
  # Note: remember to miss the trailing slash or the symlink? test fails!
  if started_from_unix || started_from_windows
    srcdir = Pathname.new("../srcdir")
  else
    srcdir = Pathname.new("./srcdir")
  end

  # TODO: could detect based on the dirname of the build dir too..
  if not srcdir.symlink?
    STDERR.puts "cmake-setup.rb: error: srcdir link '#{srcdir}' is not a link."
    Kernel.exit 1
  end
elsif non_args.length == 1
  srcdir = Pathname.new(non_args[0])
else
  STDERR.puts "cmake-setup.rb: error: need source directory, or the standard symlink."
  Kernel.exit 1
end

if not Pathname.new("#{srcdir}/CMakeLists.txt").readable?
  STDERR.puts "cmake-setup.rb: error: '#{srcdir}' doesn't contain a CMakeLists.txt"
  Kernel.exit 1
end

# Need a fullpath because we might cd out of pwd.
srcdir = srcdir.realpath

if (not started_from_unix) && (not started_from_windows)
  if (not Pathname.new("srcdir").directory?)
    FileUtils.ln_s(srcdir, 'srcdir', {:verbose => true})
  end
end

if create_unix
  puts "cmake-setup.rb: creating unix..."
  bindir = (started_from_unix) ? nil : 'unix'

  checked_remove(bindir) if clean

  do_create(bindir) {
    setup_unix(srcdir, extra_defines)
  }
end

if create_windows
  puts "cmake-setup.rb: creating windows..."
  bindir = (started_from_windows) ? nil : 'win'

  checked_remove(bindir) if clean

  do_create(bindir) {
    setup_win(srcdir, extra_defines)
  }
end



