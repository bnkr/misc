#!/usr/bin/ruby
#
# Makes a deb package of my slim theme.

require 'tempfile'
require 'optparse'
require 'fileutils'
require 'pathname'

require Pathname.new(__FILE__).dirname.realpath + "./../debian/ruby-lib/debmaker"

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

