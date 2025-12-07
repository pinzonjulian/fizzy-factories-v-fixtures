#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'
require 'active_support/inflector'
require 'shellwords'

FACTORIES_DIR = File.join(__dir__, '..', 'test', 'factories')

# Find all .yml files recursively (including subdirectories)
all_yml_files = Dir.glob(File.join(FACTORIES_DIR, '**', '*.yml')).sort

# Filter to only files that don't have a corresponding .rb file
yml_files = all_yml_files.reject do |yml_file|
  rb_file = yml_file.gsub(/\.yml$/, '.rb')
  File.exist?(rb_file)
end

puts "=" * 80
puts "FIXTURE TO FACTORY CONVERTER"
puts "=" * 80

# Step 1: Create all .rb files
puts "\n📝 STEP 1: Creating factory files..."
yml_files.each do |yml_file|
  rb_file = yml_file.gsub(/\.yml$/, '.rb')
  basename = File.basename(yml_file, '.yml')
  factory_name = basename.singularize
  
  # Create directory if needed
  FileUtils.mkdir_p(File.dirname(rb_file))
  
  # Create the .rb file with skeleton
  File.write(rb_file, "FactoryBot.define do\n  factory :#{factory_name} do\n  end\nend\n")
  relative_path = rb_file.gsub(FACTORIES_DIR + '/', '')
  puts "  ✓ Created #{relative_path}"
end

puts "\n🔄 STEP 2: Conversion prompts for Amp"
puts "=" * 80

yml_files.each do |yml_file|
  basename = File.basename(yml_file, '.yml')
  factory_name = basename.singularize
  yaml_content = File.read(yml_file)
  
  puts "\n"
  puts "FILE: test/factories/#{basename}.yml"
  puts "=" * 80
  puts <<~PROMPT
    Convert this YAML fixture to a FactoryBot factory. Output ONLY the Ruby code.
    
    YAML Fixture (test/factories/#{basename}.yml):
    ```yaml
    #{yaml_content}
    ```
    
    Follow these guidelines:
    1. Factory name should be :#{factory_name} (singular)
    2. Each top-level YAML key becomes a trait with that name
    3. Use { } blocks for dynamic values
    4. Set default attributes in the base factory
    5. Omit database IDs - FactoryBot generates them
    6. Remove fixture-specific ID generation
    7. For boolean/null values, use simple assignments
    
    Reference examples (accounts.rb and identities.rb in the same directory).
    
    OUTPUT: The complete FactoryBot.define block only, no markdown or explanation.
  PROMPT
  puts "=" * 80
end

puts "\n\n🤖 STEP 3: Calling Amp to convert fixtures..."
puts "=" * 80

yml_files.each do |yml_file|
  rb_file = yml_file.gsub(/\.yml$/, '.rb')
  basename = File.basename(yml_file, '.yml')
  factory_name = basename.singularize
  yaml_content = File.read(yml_file)
  relative_yml_path = yml_file.gsub(FACTORIES_DIR + '/', '')
  relative_rb_path = rb_file.gsub(FACTORIES_DIR + '/', '')
  
  prompt = <<~PROMPT
    Convert this YAML fixture to a FactoryBot factory. Output ONLY the Ruby code.
    
    YAML Fixture (test/factories/#{relative_yml_path}):
    ```yaml
    #{yaml_content}
    ```
    
    Follow these guidelines:
    1. Factory name should be :#{factory_name} (singular)
    2. Each top-level YAML key becomes a trait with that name
    3. Use { } blocks for dynamic values
    4. Set default attributes in the base factory
    5. Omit database IDs - FactoryBot generates them
    6. Remove fixture-specific ID generation
    7. For boolean/null values, use simple assignments
    
    Reference examples (accounts.rb and identities.rb in the same directory).
    
    OUTPUT: The complete FactoryBot.define block only, no markdown or explanation.
  PROMPT
  
  puts "\n📝 Converting #{relative_yml_path}..."
  
  # Call Amp via system command and capture output
  response = `echo #{Shellwords.escape(prompt)} | amp`
  
  if $?.success? && !response.empty?
    File.write(rb_file, response)
    puts "✓ Updated #{relative_rb_path}"
  else
    puts "✗ Failed to convert #{relative_yml_path}"
  end
end

puts "\n\n✅ Conversions complete!"
puts "\n📝 Add these methods to FactoryTestHelper:"

yml_files.each do |yml_file|
  basename = File.basename(yml_file, '.yml')
  puts "\n  def #{basename}(trait)"
  puts "    create(:#{basename.singularize}, trait)"
  puts "  end"
end
