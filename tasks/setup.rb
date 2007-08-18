# $Id$

require 'rubygems'
require 'ostruct'

PROJ = OpenStruct.new

PROJ.name = nil
PROJ.summary = nil
PROJ.description = nil
PROJ.changes = nil
PROJ.authors = nil
PROJ.email = nil
PROJ.url = nil
PROJ.version = ENV['VERSION'] || '0.0.0'
PROJ.rubyforge_name = nil
PROJ.exclude = %w(tmp$ bak$ ~$ CVS \.svn)

# Rspec
PROJ.specs = FileList['spec/**/*_spec.rb']
PROJ.spec_opts = []

# Test::Unit
PROJ.tests = FileList['test/**/test_*.rb']
PROJ.test_file = 'test/all.rb'
PROJ.test_opts = []

# Rcov
PROJ.rcov_opts = ['--sort', 'coverage', '-T']

# Rdoc
PROJ.rdoc_opts = []
PROJ.rdoc_include = %w(^lib ^bin ^ext txt$)
PROJ.rdoc_exclude = %w(extconf\.rb$ ^Manifest\.txt$)
PROJ.rdoc_main = 'README.txt'
PROJ.rdoc_remote_dir = nil

# Extensions
PROJ.extensions = FileList['ext/**/extconf.rb']
PROJ.ruby_opts = %w(-w)
PROJ.libs = []
%w(lib ext).each {|dir| PROJ.libs << dir if test ?d, dir}

# Gem Packaging
PROJ.files =
  if test ?f, 'Manifest.txt'
    files = File.readlines('Manifest.txt').map {|fn| fn.chomp.strip}
    files.delete ''
    files
  else [] end
PROJ.executables = PROJ.files.find_all {|fn| fn =~ %r/^bin/}
PROJ.dependencies = []
PROJ.need_tar = true
PROJ.need_zip = false

# Import the rake tasks
FileList['tasks/*.rake'].each {|task| import task}

# Setup some constants
WIN32 = %r/win32/ =~ RUBY_PLATFORM unless defined? WIN32

DEV_NULL = WIN32 ? 'NUL:' : '/dev/null'

def quiet( &block )
  io = [STDOUT.dup, STDERR.dup]
  STDOUT.reopen DEV_NULL
  STDERR.reopen DEV_NULL
  block.call
ensure
  STDOUT.reopen io.first
  STDERR.reopen io.last
end

DIFF = if WIN32 then 'diff.exe'
       else
         if quiet {system "gdiff", __FILE__, __FILE__} then 'gdiff'
         else 'diff' end
       end unless defined? DIFF

SUDO = if WIN32 then ''
       else
         if quiet {system 'which sudo'} then 'sudo'
         else '' end
       end

RCOV = WIN32 ? 'rcov.cmd'  : 'rcov'
GEM  = WIN32 ? 'gem.cmd'   : 'gem'

%w(rcov rspec rubyforge).each do |g|
  begin
    gem g
    Object.instance_eval {const_set "HAVE_#{g.upcase}", true}
  rescue LoadError
    Object.instance_eval {const_set "HAVE_#{g.upcase}", false}
  end
end

# Reads a file at +path+ and spits out an array of the +paragraphs+
# specified.
#
#    changes = paragraphs_of('History.txt', 0..1).join("\n\n")
#    summary, *description = paragraphs_of('README.txt', 3, 3..8)
#
def paragraphs_of(path, *paragraphs)
  File.read(path).delete("\r").split(/\n\n+/).values_at(*paragraphs)
end

# EOF
