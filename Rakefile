require 'pathname'

BASE_PATH = Pathname(IO.readlines('./BASE_PATH').first.chomp)

RAILS_PATH  = BASE_PATH + 'rails'
GUIDES_PATH = BASE_PATH + 'guides'
PAGES_PATH  = BASE_PATH + 'ruby-china.github.io'

RAILS_GUIDE_SOURCE_PATH = RAILS_PATH + 'guides/source/'

def update_rails_repo!
  FileUtils.cd(RAILS_PATH.expand_path) { `git pull origin master` }
end

def get_rails_latest_sha1
  sha1 = nil
  FileUtils.cd(RAILS_PATH.expand_path) { sha1 = `git rev-parse HEAD` }
  sha1[0, 7]
end

task :sanity_checks do
  abort("Abort. please clone the rails/rails repo under #{BASE_PATH}") if !File.exist? RAILS_PATH.expand_path
  abort("Abort. please clone the ruby-china/guides repo under #{BASE_PATH}") if !File.exist? GUIDES_PATH.expand_path
end

namespace :guides do
  desc 'Generate guides (for authors), use ONLY=foo to process just "foo.md"'
  task :generate => 'generate:html'

  desc 'Deploy generated guides to github pages repository'
  task :deploy => :sanity_checks do
    ENV['RAILS_VERSION'] = get_rails_latest_sha1
    ENV['ALL']  = '1'
    ENV['GUIDES_LANGUAGE'] = 'zh-CN'
    Rake::Task['guides:generate:html'].invoke

    # the dot will copy contents under a folder, instead of copy the folder.
    FileUtils.cp_r("#{GUIDES_PATH.expand_path}/output/zh-CN/.", PAGES_PATH.expand_path)

    Dir.chdir(PAGES_PATH.expand_path) do
      `git add -A .`
      `git commit -m '#{%Q[Site updated @ #{Time.now.strftime("%a %b %-d %H:%M:%S %Z %Y")}]}'`
      `git push origin master`
    end

    puts 'Deploy Complete. : )'
  end

  desc 'Update a given English guide'
  task :update_guide => :sanity_checks do
    update_rails_repo!

    guide_to_be_updated = ARGV.last
    guide_path = (RAILS_GUIDE_SOURCE_PATH + guide_to_be_updated).expand_path

    if File.exist? guide_path
      FileUtils.cp(guide_path, "#{GUIDES_PATH.expand_path}/source/")
      puts "Update: #{guide_path} Complete. : )"
    else
      `ls #{guide_path}`
    end

    # trick rake that ARGV.last is a task :P
    task guide_to_be_updated.to_sym do; end
  end

  desc 'Update all English guides'
  task :update_guides => :sanity_checks do
    update_rails_repo!

    FileUtils.cp_r(Pathname.glob("#{RAILS_GUIDE_SOURCE_PATH.expand_path}/*.md"), "#{GUIDES_PATH.expand_path}/source")

    puts 'Update all English Guides. : D'
  end

  namespace :generate do
    desc "Generate HTML guides"
    task :html do
      ENV["WARN_BROKEN_LINKS"] = "1" # authors can't disable this
      ruby "rails_guides.rb"
    end
  end

  desc "Show help"
  task :help do
    puts <<-help

Guides are taken from the source directory, and the resulting HTML goes into the
output directory. Assets are stored under files, and copied to output/files as
part of the generation process.

All this process is handled via rake tasks, here's a full list of them:

#{%x[rake -T]}
Some arguments may be passed via environment variables:

  WARNINGS=1
    Internal links (anchors) are checked, also detects duplicated IDs.

  ALL=1
    Force generation of all guides.

  ONLY=name
    Useful if you want to generate only one or a set of guides.

    Generate only association_basics.html:
      ONLY=assoc

    Separate many using commas:
      ONLY=assoc,migrations

  GUIDES_LANGUAGE
    Use it when you want to generate translated guides in
    source/<GUIDES_LANGUAGE> folder (such as source/es)

  EDGE=1
    Indicate generated guides should be marked as edge.

Examples:
  $ rake guides:generate ALL=1
  $ rake guides:generate EDGE=1
  $ rake guides:generate:kindle EDGE=1
  $ rake guides:generate GUIDES_LANGUAGE=es
    help
  end
end

task :default do
  Rake::Task['guides:generate'].invoke
end
