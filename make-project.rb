#!/usr/bin/ruby
# Make a project directory using my own conventions.

require 'optparse'
require 'pathname'
require 'fileutils'

# Validation error.
class SettingsError < RuntimeError; end

# Settings properties.
class Settings
  attr_reader :project_dir
  attr_reader :overwrite
  attr_reader :verbose
  attr_reader :description

  alias verbose? verbose
  alias overwrite? overwrite

  attr_reader :bcmake_src
  attr_reader :bsd3_license_file
  attr_reader :cmakelists_template
  attr_reader :default_doxyfile
  attr_reader :git_links_dir
  attr_reader :release_links_dir
  attr_reader :release_dir
  attr_reader :build_dir

  # Calls parse! if not nil
  def initialize(args = nil)
    @overwrite = false
    @verbose = false
    @description = nil
    parse!(args) if args != nil
  end

  # Parses.  Can exit on --help, etc.
  def parse!(args)
    parser = make_parser
    others = parser.parse(args)

    set_lib_files

    if others.length == 0
      raise SettingsError, "a project directory is required"
    elsif others.length != 1
      raise SettingsError, "too many arguments: a single project directory is required"
    else
      @project_dir = Pathname.new(others[0])

      if @project_dir.exist?
        if ! @project_dir.directory?
          raise SettingsError, "#{@project_dir}: not a directory"
        elsif ! overwrite?
          raise SettingsError, "#{@project_dir}: exists and --overwrite is not given"
        end
      end
    end

    raise SettingsError, "--description is not given" if @description == nil
  end

  private

  def make_parser
    p = OptionParser.new
    p.banner += " dir\nSets up a project using standard conventions."

    p.separator "\nOptions:"
    p.on("--help", "help message and quit") {
      puts p
      Kernel.exit 0
    }
    p.on("--description=DESCR", "description of the git repository") {|str|
      @description = str
    }

    p.on("--overwrite", "overwrite an existing project directory") {
      @overwrite = true
    }
    p.on("--verbose", "print what is happening") {
      @verbose = true
    }

    p
  end

  def set_lib_files
    check_lib = lambda do |what,f,is_dir|
      f = Pathname.new(f)
      if (f.directory? && ! is_dir) || (! f.directory? && is_dir) || ! f.exist?
        raise SettingsError, "#{what} is not where is should be: #{f}"
      end
      f
    end

    check_lib_file = lambda do |what,f| check_lib.call(what, f, false) end
    check_lib_dir = lambda do |what,f| check_lib.call(what, f, true) end

    @bcmake_src = check_lib_dir.call("bcmake repos", '/home/bunker/src/_git-submodules/bcmake-src.git')

    @bsd3_license_file = check_lib_file.call(
      "bsd3 license file", "/home/bunker/src/build-scripting/COPYING.3-clause-bsd"
    )

    @cmakelists_template = check_lib_file.call(
      'template cmake file', "/home/bunker/src/bcmake/doc/CMakeLists-template.cmake"
    )

    @default_doxyfile = check_lib_file.call(
      "default doxyfile", '/home/bunker/src/build-scripting/Doxyfile.default'
    )

    @git_links_dir = check_lib_dir.call(
      'git repos links dir', "/home/bunker/src/bunkerprivate/gitweb/gitlinks"
    )

    @release_links_dir = check_lib_dir.call(
      'release links dir', "/home/bunker/src/bunkerprivate/rel"
    )

    @release_dir = check_lib_dir.call(
      'release dir', "/home/bunker/var/project-release"
    )

    @build_dir = check_lib_dir.call(
      'build dir', "/home/bunker/var/build"
    )
  end
end

# An action failed.
class ActionError < RuntimeError; end

# Singleton abstraction for things that will happen in this program.
class Action
  def self.verbose=(value); @@verbose = value; end
  def self.verbose?; @@verbose; end

  def self.cmd(string)
    puts string if self.verbose?
    ret = system(string)
    raise ActionError, "cmd(#{string})" if not ret
  end

  def self.mkdir_p(dir)
    dir = Pathname.new(dir)
    cmd = "mkdir -p #{dir}" if self.verbose?
    if ! dir.exist?
      puts cmd if self.verbose?
      FileUtils.mkdir_p(dir)
    elsif ! dir.directory?
      raise ActionError, "mkdir_p(#{dir}): exists but is not a directory"
    elsif self.verbose?
      puts cmd + " (already exists)"
    end
  end

  def self.chdir(dir)
    puts "cd #{dir}" if self.verbose?
    action_guard("chdir(#{dir})") {
      Dir.chdir(dir)
    }
  end

  def self.ln(target, name)
    action_guard("ln(#{target}, #{name}})") {
      t = Pathname.new(target)
      cmd = "ln #{target} #{name}"
      if File.exist?(name)
        puts cmd + " (already exist)" if self.verbose?
      else
        puts cmd if self.verbose?
        FileUtils.ln(target, name)
      end
    }
  end

  def self.ln_s(target, name)
    action_guard("ln_s(#{target}, #{name}})") {
      t = Pathname.new(target)
      cmd = "ln -s #{target} #{name}"
      if FileTest.symlink?(name)
        puts cmd + " (already exist)" if self.verbose?
      else
        puts cmd if self.verbose?
        FileUtils.ln_s(target, name)
      end
    }
  end

  def self.touch(file)
    action_guard("touch(#{file})") {
      FileUtils.touch(file, {:verbose, self.verbose?})
    }
  end

  def self.cp(from, to)
    action_guard("cp(#{from}, #{to})") {
      FileUtils.cp(from, to, {:verbose, self.verbose?})
    }
  end

  def self.in_directory(dir)
    oldpwd = Dir.pwd
    begin
      self.chdir(dir)
      yield
    ensure
      self.chdir(oldpwd)
    end
  end

  private
  def self.action_guard(command)
    begin
      yield
    rescue RuntimeError => e
      raise ActionError, "#{command}: #{e}"
    end
  end
end

class CommandLine
  def initialize(args)
    @args = args
    @settings = nil
  end

  # Runs and interprets error exceptions.
  def run!
    begin
      do_run
    rescue ActionError => e
      STDERR.puts "action error: #{e}"
      Kernel.exit(1)
    rescue OptionParser::ParseError, SettingsError => e
      STDERR.puts "make-project: #{e}"
      Kernel.exit(1)
    end
  end

  private

  # Runs and raises exceptions on errors.
  def do_run
    setup
    s = @settings

    Action.mkdir_p(s.project_dir)
    Action.chdir(s.project_dir)

    make_git
    make_files
    make_buildsystem
    make_build_dir
    make_website
    make_release_files

    nil
  end

  def setup
    @settings = Settings.new(@args)
    Action.verbose = @settings.verbose?
    nil
  end

  # Initialise git.
  def make_git
    # Safe on an existing project, according to the man page.
    Action.cmd("git init")

    File.open(".git/description", 'w') {|io| io.puts @settings.description }

    Action.mkdir_p("build-aux")
    if ! File.exist?(@settings.project_dir + "./build-aux/bcmake")
      Action.cmd("git submodule add \"#{@settings.bcmake_src}\" build-aux/bcmake")
      Action.cmd("git commit -a -m \"Add bcmake submodule.\"")
    elsif @settings.verbose?
      puts "bcmake submodule already exists"
    end

    ig = Pathname.new('.gitignore')
    if not ig.exist?
      ig.open('w') {|io|
        io.puts "*.sw[po]"
        io.puts "tags"
      }
      Action.cmd("git add .gitignore")
      Action.cmd("git commit -m \"Add ignore files.\"")
    elsif @settings.verbose?
      puts ".gititnore already exists"
    end
    nil
  end

  # Add license, readme, and so on.
  def make_files
    Action.ln(@settings.bsd3_license_file, 'COPYING')
    # TODO:
    #   use the basic readme file from ~/src/defer-screensaver but require that
    #   the introduction is written also.
    Action.touch('README')
    Action.touch('CHANGELOG')
    if Pathname.new('README').size <= 1
      fail "README must be written first"
    end
    Action.cmd("git add README")
    Action.cmd("git add CHANGELOG")
    Action.cmd("git add COPYING")
    begin
      Action.cmd("git commit -m \"Add info files.\"")
    rescue ActionError
    end
    nil
  end

  def make_buildsystem
    Action.cp(@settings.cmakelists_template, "CMakeLists.txt")
    proj = File.basename(Dir.pwd)
    Action.cmd("sed -i \"s/PROJECT_NAME_HERE/#{proj}/\" CMakeLists.txt")
    Action.mkdir_p('test')
    Action.touch('test/CMakeLists.txt')

    Action.ln(@settings.default_doxyfile, "Doxyfile.default")

    Action.touch('build-aux/description.txt')
    Action.touch('build-aux/install-readme.txt')
    STDERR.puts "warning: description.txt must be written manually"

    Action.cmd("git add CMakeLists.txt")
    Action.cmd("git add Doxyfile.default")
    Action.cmd("git add test/CMakeLists.txt")
    Action.cmd("git add build-aux/description.txt")
    Action.cmd("git add build-aux/install-readme.txt")

    if Pathname.new("build-aux/description.txt").size <= 1
      fail "build-aux/description.txt must be written manually"
    end

    begin
      Action.cmd("git commit -m \"Add buildsystem.\"")
    rescue ActionError
    end

    nil
  end

  def make_website
    target = Pathname.new(Dir.pwd) + "./.git"
    project = File.basename(Dir.pwd)
    name = @settings.git_links_dir + "./#{project}"
    Action.ln_s(target, name)

    target = Pathname.new("#{@settings.release_dir}/#{project}")
    name = Pathname.new("#{@settings.release_links_dir}/#{project}")

    Action.ln_s(target, name)

    STDERR.puts "warning: project must be added to bunkerprivate database manually"

    nil
  end

  def make_release_files
    project = File.basename(Dir.pwd)
    d = Pathname.new("#{@settings.release_dir}/#{project}")
    Action.mkdir_p(d)
    nil
  end

  def make_build_dir
    project = File.basename(Dir.pwd)
    bin_dir = @settings.build_dir + "./#{project}"
    project_dir = Dir.pwd
    Action.mkdir_p(bin_dir)
    Action.in_directory(bin_dir) {
      Action.cmd("cmake-setup.rb \"#{project_dir}\"")
    }
    nil
  end
end

CommandLine.new(ARGV).run!
