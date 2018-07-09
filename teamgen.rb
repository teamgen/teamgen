require 'optparse'
require 'yaml'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: teamgen.rb [options] [<directory>]"

  options[:config] = 'teamgen.yml'
  opts.on( '-c', '--config FILE', 'Specify a configuration file.' ) do |file|
    options[:config] = file
  end

  opts.on( '-h', '--help', 'Print this help message' ) do
    puts opts
    exit
  end
end

optparse.parse!

# directory = if ARGV.empty?
#               "./"
#             elsif ARGV.length == 1
#               ARGV.first
#             else
#               puts optparse
#               exit(-1)
#             end

config = YAML.load_file(options[:config])
p config

config['services'].each do |service|
  directory = service['name']
  Dir.mkdir(directory)

  entry = ""
  if service['framework'] == nil
    entry = 'main.rb'
    File.open("#{directory}/#{entry}", 'w') do |f|
      f.write("puts 'Hello World'\n")
    end
  else
    puts "unsupported keyword framework"
    exit(-1)
  end

  if service['language'] === 'ruby'
    version = '2.5'
    File.open("#{directory}/Dockerfile", 'w') do |f|
      f.write("FROM ruby:#{version}\n")
      f.write("RUN bundle config --global frozen 1\n")
      f.write("WORKDIR /usr/src/app\n")
      f.write("COPY Gemfile Gemfile.lock ./\n")
      f.write("RUN bundle install\n")
      f.write("COPY . .\n")
      f.write("CMD ['./#{entry}']\n")
    end

    File.open("#{directory}/README.md", "w") do |f|
      f.write("# #{service['name']}\n")
      f.write("\n")
      f.write("## To Run\n")
      f.write("```\n")
      f.write("docker build -t #{service['name']} .\n")
      f.write("docker run -it --rm --name my-running-script -v \"$PWD\":/usr/src/myapp -w /usr/src/myapp ruby:#{version} ruby #{entry}\n")
      f.write("```\n")
    end

    File.open("#{directory}/Gemfile", "w") do |f|
    end

    commands = [
      'ruby:2.5 bundle install'
    ]

    if service['linter']
      if service['linter']['name'] === 'rubocop'
        commands.push('bundle add rubocop --group=development')
        File.open("#{directory}/.rubocop.yml", "w") do |f|
          f.write("AllCops:\n")
          f.write("  TargetRubyVersion: #{version}\n")
        end
      else
        puts "unsupported linter #{service['linter']['name']}"
        exit(-1)
      end
    end

    commands = commands.join(' && ')
    `cd #{directory} && docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app #{commands}`
  else
    puts "unsupported language #{service['language']}"
    exit(-1)
  end
end