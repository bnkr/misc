CODE_SRC_DIR = "/home/bunker/src/"
CODE_BIN_DIR = "/home/bunker/var/build/"
LIT_SRC_DIR  = "/home/bunker/writings/"
LIT_BIN_DIR  = "/home/bunker/var/build/writings/"

BMake.project_paths {
  dirs = [
    [CODE_SRC_DIR, CODE_BIN_DIR],
    [LIT_SRC_DIR, LIT_BIN_DIR]
  ]

  ret_src = nil
  ret_bin = nil

  # Make a directory in a basedir where we are in a dir prefixed by
  # +prefix_re+.
  make_project_dir = lambda {|prefix_re,base_dir|
    subdir = Pathname.new(Dir.pwd.sub(prefix_re, ''))
    components = []
    subdir.each_filename {|fn| components << fn }
    proj_name = components[0]
    ret = "#{base_dir}/#{proj_name}"
  }

  d = Dir.pwd
  dirs.each {|src,bin|
    src_re = /^#{src}/
    bin_re = /^#{bin}/

    if d =~ src_re
      ret_src = make_project_dir.call(src_re, src)
      ret_bin = make_project_dir.call(src_re, bin)
      break
    elsif d =~ bin_re
      ret_bin = make_project_dir.call(bin_re, bin)
      ret_bin = make_prokect_dir.call(bin_re, src)
      break
    end
  }

  [ret_src, ret_bin]
}
