require 'set'

desc 'Builds every service gem'
task 'build' do
  BuildTools::Services.each do |service|
    Rake::Task["build:aws-sdk-#{service.identifier}"].invoke
  end
end

desc 'Build one service, e.g. `rake build  build:aws-sdk-dynamodb`'
task 'build:aws-sdk-*'

rule /^build:aws-sdk-\w+$/ do |task|
  # legacy generator
  identifier = task.name.split('-').last
  service = BuildTools::Services[identifier]
  files = AwsSdkCodeGenerator::GemBuilder.new(service: service).each
  writer = BuildTools::FileWriter.new(directory: "gems/#{service.gem_name}")
  writer.write_files(files)
end

# Aws::STS is generated directly into the `aws-sdk-core` gem.
# It is need to provide session credentials and assume role support.
# Only building source, but not gemspecs, version file, etc.
task 'build:aws-sdk-sts' do
  sts = BuildTools::Services.service('sts')
  sts.gem_dependencies.clear
  generator = AwsSdkCodeGenerator::CodeGenerator.new(service: sts)
  files = generator.src_files(prefix: 'aws-sdk-sts')
  writer = BuildTools::FileWriter.new(directory: 'gems/aws-sdk-core/lib')
  writer.write_files(files)
end
