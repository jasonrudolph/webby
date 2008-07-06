require 'optparse'
require 'rake'

module Webby

# The Webby::Main class contains all the functionality needed by the +webby+
# command line application.
#
class Main

  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    self.new.run args
  end

  # Create a new Main webby object for building websites.
  #
  def initialize
    @stdout = $stdout
  end

  # Runs the main webby application. The command line arguments are passed
  # in to this method as an array of strings. The command line arguments are
  # parsed to figure out which webby sub-command or rake task to invoke.
  #
  def run( args )
    args = args.dup

    case args[0]
    when 'gen', 'generate'
      args.shift
      gen = Generator.new
      gen.run args
    else
      parse args
      init args
      rake
    end
  end

  # Parse the command line _args_ for options and commands to invoke.
  #
  def parse( args )
    opts = OptionParser.new
    opts.banner = 'Usage: webby [options] target [target args]'

    opts.separator ''
    opts.on('-D', '--describe [PATTERN]', 'describe the tasks (matching optional PATTERN), then exit') {|pattern| app.do_option('--describe', pattern)}
    opts.on('-P', '--prereqs', 'display the tasks and dependencies, then exit') {app.do_option('--prereqs', nil)}
    opts.on('-T', '--tasks [PATTERN]', 'display the tasks (matching optional PATTERN) with descriptions, then exit') {|pattern| app.do_option('--tasks', pattern)}
    opts.on('-t', '--trace', 'turn on invoke/execute tracing, enable full backtrace') {app.do_option('--trace', nil)}

    opts.separator ''
    opts.separator 'common options:'

    opts.on_tail( '-h', '--help', 'show this message' ) do
      @stdout.puts opts
      exit
    end
    opts.on_tail( '--version', 'show version' ) do
      @stdout.puts "Webby #{::Webby::VERSION}"
      exit
    end

    opts.parse %[--help] if args.empty?
    opts.parse! args

    ARGV.replace Array(args.shift)
    args
  end

  # Initialize the Rake application object and load the core rake tasks, the
  # site specific rake tasks, and the site specific ruby code. Any extra
  # command line arguments are converted into a page name and directory that
  # might get created (depending upon the task invoked).
  #
  def init( args )
    # Make sure we're in a folder with a Sitefile
    app.do_option('--rakefile', 'Sitefile')
    app.do_option('--nosearch', nil)

    if ! app.have_rakefile
      @stdout.puts "    Sitefile not found"
      abort
    end

    # Load the default webby tasks from the library tasks folder
    Dir.glob(::Webby.libpath(%w[webby tasks *.rake])).sort.each {|fn| import fn}

    # Load the website tasks from the tasks folder
    Dir.glob(::File.join(%w[tasks *.rake])).sort.each {|fn| import fn}

    # Load all the ruby files in the lib folder and sub-folders
    Dir.glob(::File.join(%w[lib ** *.rb])).sort.each {|fn| require fn}

    # Capture the command line args for use by the Rake tasks
    args = Webby.site.args = OpenStruct.new(
      :raw => args,
      :page => args.join('-').downcase
    )
    args.dir = Resources::File.dirname(args.page)
    args.slug = Resources::File.basename(args.page)
    args.title = Resources::File.basename(args.raw.join(' ')).titlecase

    Object.const_set(:SITE, Webby.site)
  end

  # Execute the rake command.
  #
  def rake
    app.init 'webby'
    app.load_rakefile
    app.top_level
  end

  # Return the Rake application object.
  #
  def app
    Rake.application
  end

  # Search for the "Sitefile" starting in the current directory and working
  # upwards through the filesystem until the root of the filesystem is
  # reached. If a "Sitefile" is not found, a RuntimeError is raised.
  #
  def find_sitefile
    here = Dir.pwd
    while ! app.have_rakefile
      Dir.chdir("..")
      if Dir.pwd == here || options.nosearch
        fail "No Sitefile found"
      end
      here = Dir.pwd
    end
  end

end  # class Main
end  # module Webby

# :stopdoc:
# Monkey patches so that rake displays the correct application name in the
# help messages.
#
class Rake::Application
  def display_prerequisites
    tasks.each do |t|
      puts "#{name} #{t.name}"
      t.prerequisites.each { |pre| puts "    #{pre}" }
    end
  end

  def display_tasks_and_comments
    displayable_tasks = tasks.select { |t|
      t.comment && t.name =~ options.show_task_pattern
    }
    if options.full_description
      displayable_tasks.each do |t|
        puts "#{name} #{t.name_with_args}"
        t.full_comment.split("\n").each do |line|
          puts "    #{line}"
        end
        puts
      end
    else
      width = displayable_tasks.collect { |t| t.name_with_args.length }.max || 10
      max_column = 80 - name.size - width - 7
      displayable_tasks.each do |t|
        printf "#{name} %-#{width}s  # %s\n",
          t.name_with_args, truncate(t.comment, max_column)
      end
    end
  end

  # Provide standard execption handling for the given block.
  def standard_exception_handling
    begin
      yield
    rescue SystemExit => ex
      # Exit silently with current status
      exit(ex.status)
    rescue SystemExit, GetoptLong::InvalidOption => ex
      # Exit silently
      exit(1)
    rescue Exception => ex
      # Exit with error message
      $stderr.puts "webby aborted!"
      $stderr.puts ex.message
      if options.trace
        $stderr.puts ex.backtrace.join("\n")
      else
        $stderr.puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
        $stderr.puts "(See full trace by running task with --trace)"
      end
      exit(1)
    end
  end
end
# :startdoc:

Webby.require_all_libs_relative_to(__FILE__)

# EOF
