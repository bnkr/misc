#!/usr/bin/ruby
#
# Makes a deb package of my slim theme.

require 'tempfile'
require 'optparse'
require 'fileutils'
require 'pathname'
require 'date'

# Based on an existing filesystem, create a debian package.
class DebMaker
  # TODO:
  #   License.  A copyright file is also required.  Possibly also some differing
  #   install stuff so the deb gets put in the right plcage.

  ConfigFields = Struct.new(
    # Path to the directory containing the filesystem mirror.
    :root,
    # Name of the package.
    :package,
    # Section
    :section,
    # One-line description
    :short_description,
    # Long text of description.
    :description,
    # Name and email (preferably like "name <email>")
    :maintainer,
    # Version of package
    :version,
    # Debian release number.
    :release,
    # List of packages to depend on
    :depends,
    # List of packages to recommend
    :recommends
  )

  class Config < ConfigFields
    def initialize
      super
      self.release = 1
      self.depends = []
      self.recommends = []
    end

    def validate
      self.each_pair {|sym,obj|
        if obj == nil
          fail "#{sym} may not be nil"
        end
      }
    end

    def full_version
      self.version + "-" + self.release.to_s
    end

    def architecture
      # TODO: get from dpkg --print-architecture
      "i386"
    end
  end

  attr_reader :config

  # Yields a configuration object.
  def initialize
    @config = DebMaker::Config.new
    yield @config
    @config.validate
  end

  # Create the package.  Returns a path to the package.
  def make(output_dir)
    create_debian_dir

    arch = @config.architecture
    package_name = @config.package + "_#{@config.full_version}_#{arch}.deb"
    package_path = Pathname.new(output_dir) + package_name

    system("fakeroot dpkg-deb -b \"#{@config.root}\" \"#{package_path}\"")

    package_path
  end

  def self.lintian(package)
    system("lintian \"#{package}\"")
  end

  private

  def create_debian_dir
    in_dir(@config.root) {
      FileUtils.mkdir('DEBIAN')

      # TODO:
      #   Do the md5sums.

      File.open('DEBIAN/control', 'w') {|io|
        write_control(io)
      }
    }
  end

  def write_control(io)
    io.puts "Package: #{@config.package}"
    io.puts "Version: #{@config.full_version}"
    io.puts "Architecture: #{@config.architecture}"
    io.puts "Description: #{@config.short_description}"
    # Wordwrap.
    io.puts @config.description.gsub(/.{1,79}(?:\s|\Z)/) { " #{$&}\n" }
    io.puts " ."
    io.puts "Priority: optional"
    io.puts "Section: #{@config.section}"
    io.puts "Maintainer: #{@config.maintainer}"
    io.puts "Depends: #{@config.depends.join(', ')}" unless @config.depends.empty?
    io.puts "Recommends: #{@config.recommends.join(', ')}" unless @config.recommends.empty?
    # TODO: calculate installed size
    #  io.puts "Installed-Size: "
  end

  def in_dir(name)
    old_dir = Dir.pwd
    begin
      Dir.chdir(name)
      yield
    ensure
      Dir.chdir(old_dir)
    end
  end
end

class CommandLine
  def initialize(args)
    @args = args
  end

  def run!
    exit_fail "no arguments are allowed" unless @args.empty?

    output_dir = Pathname.pwd
    input_dir = Pathname.pwd.realpath + "./bunker-blue"

    in_tempdir {|root_path|
      theme_dir = "usr/share/slim/themes/bunker-blue"

      FileUtils.mkdir_p(theme_dir)
      # For some reason this dereferences the symlinsk.
      #  FileUtils.cp(input_dir + "./background.png", theme_dir, {:preserve => true})
      # TODO: The symlink should be a relative path.
      system("cp -a \"#{input_dir}/background.png\" \"#{theme_dir}\"")
      FileUtils.cp(input_dir + "./panel.png", theme_dir)
      FileUtils.cp(input_dir + "./slim.theme", theme_dir)

      #  system("ls --color=always -la #{theme_dir}")

      dm = DebMaker.new {|conf|
        conf.root = root_path
        conf.package = "slim-theme-bunker-blue"
        conf.version = Date.today.strftime("%Y%m%d")
        conf.short_description = "A blue fractal theme for the slim display manager."
        conf.description = "Alter current_theme in /etc/slim.conf to get this theme to display."
        conf.maintainer = "James Webber <bunkerprivate@gmail.com>"
        conf.section = "x11"
        conf.release = 1
        conf.depends << "slim"
        conf.depends << "bunker-fractal-wallpapers"
      }

      verbose_msg "making package"
      deb = dm.make(output_dir)

      verbose_msg "running lintian on #{deb}"
      DebMaker.lintian(deb)
    }
  end

  private

  ##################
  ## Utility Bits ##
  ##################

  def in_tempdir
    Dir.mktmpdir('slim-theme-deb-') {|path|
      verbose_msg "created tempdir #{path}"

      old_wd = Dir.pwd
      begin
        Dir.chdir(path)
        yield path
      ensure
        Dir.chdir(old_wd)
      end
    }
  end

  def exit_fail(message)
    STDERR.puts "#{File.basename($0)}: #{message}"
    Kernel.exit 1
  end

  def verbose_msg(message)
    puts message
  end
end

CommandLine.new(ARGV).run!

