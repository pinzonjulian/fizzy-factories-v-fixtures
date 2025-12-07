#!/usr/bin/env ruby

require 'fileutils'
require 'yaml'
require 'open3'
require 'tmpdir'
require 'active_support/core_ext/string/inflections'

FACTORIES_DIR = File.join(__dir__, '..', 'test', 'factories')
EXCLUDED_FILES = [] # Already converted

# Find all .yml files recursively (including nested directories)
yml_files = Dir.glob(File.join(FACTORIES_DIR, '**', '*.yml')).reject do |file|
  relative_path = file.sub("#{FACTORIES_DIR}/", '')
  rb_path = file.gsub('.yml', '.rb')
  EXCLUDED_FILES.include?(relative_path) || File.exist?(rb_path)
end

puts "Found #{yml_files.count} fixture files to convert"

yml_files.each do |yml_file|
  basename = File.basename(yml_file, '.yml')
  dir = File.dirname(yml_file)
  rb_file = File.join(dir, "#{basename}.rb")
  
  # Create empty .rb file if it doesn't exist
  unless File.exist?(rb_file)
    puts "\n📝 Creating #{basename}.rb..."
    File.write(rb_file, "FactoryBot.define do\n  factory :#{basename} do\n  end\nend\n")
  end
  
  # Read the YAML file
  yaml_content = File.read(yml_file)
  
  puts "\n🔄 Converting #{basename}.yml to factory..."
  
  # Parse fixture names and attributes from raw YAML (can't use YAML.load due to ERB)
  fixtures = {}
  current_fixture = nil
  yaml_content.each_line do |line|
    if line =~ /^(\w+):$/  # Top-level fixture name (no indentation)
      current_fixture = $1
      fixtures[current_fixture] = []
    elsif current_fixture && line =~ /^  (\w+):/  # Attribute (2-space indentation)
      fixtures[current_fixture] << $1
    end
  end
  
  fixture_summary = fixtures.map do |name, attrs|
    "  - #{name}: #{attrs.join(', ')}"
  end.join("\n")

  # Create the prompt for Amp
  prompt = <<~PROMPT
    Convert this YAML fixture file to a FactoryBot factory in Ruby.

    SOURCE: test/factories/#{basename}.yml
    TARGET: test/factories/#{basename}.rb

    YAML CONTENT:
    ```yaml
    #{yaml_content}
    ```

    FIXTURES TO CONVERT (each becomes a trait with ALL its attributes):
#{fixture_summary}

    CRITICAL REQUIREMENTS:
    
    1. **EVERY fixture record becomes a trait** - Create one trait for each top-level YAML key
    2. **EVERY attribute must be preserved** - Each trait MUST include ALL attributes from its YAML entry (except `id`)
    3. **Exact value preservation** - Use the exact values from the YAML. For ERB expressions like `<%= Time.current.to_fs(:db) %>`, convert to equivalent Ruby blocks
    4. **Association references** - Convert YAML references (e.g., `account: 37s_uuid`) to FactoryBot associations: `association :account, :37s` or `association :account, factory: [:account, :"37s"]`
    5. **No attribute omission** - If a fixture has 5 attributes, its trait must have 5 attributes (minus `id`)

    ATTRIBUTE CONVERSION RULES:
    - `id: <%= ... %>` → OMIT (FactoryBot generates IDs)
    - `name: "David"` → `name { "David" }`
    - `role: member` → `role { "member" }` (quote string enums)
    - `verified_at: <%= Time.current.to_fs(:db) %>` → `verified_at { Time.current }`
    - `account: 37s_uuid` → `association :account, :37s` (reference to account fixture)
    - `identity: david` → `association :identity, :david` (reference to identity fixture)
    - `external_account_id: <%= ... %>` → OMIT (auto-generated)
    - Boolean `true`/`false` → `attribute { true }` or `attribute { false }`
    - Integer `5` → `attribute { 5 }`

    FACTORY STRUCTURE:
    ```ruby
    FactoryBot.define do
      factory :#{basename.singularize}, class: "#{basename.singularize.camelize}" do
        # Base factory with minimal/no defaults
        
        trait :fixture_name_1 do
          # ALL attributes from fixture_name_1 YAML entry
        end
        
        trait :fixture_name_2 do
          # ALL attributes from fixture_name_2 YAML entry  
        end
        # ... one trait per fixture
      end
    end
    ```

    EXAMPLE - Given this YAML:
    ```yaml
    david:
      id: <%= ActiveRecord::FixtureSet.identify("david", :uuid) %>
      name: David
      role: member
      identity: david
      account: 37s_uuid
      verified_at: <%= Time.current.to_fs(:db) %>
    ```
    
    OUTPUT this trait (note: ALL 5 non-id attributes preserved):
    ```ruby
    trait :david do
      name { "David" }
      role { "member" }
      association :identity, :david
      association :account, :"37s"
      verified_at { Time.current }
    end
    ```

    IMPORTANT OUTPUT FORMAT:
    - Your response must contain ONLY Ruby code
    - NO markdown, NO explanations, NO prose
    - Start with: FactoryBot.define do
    - End with: end
  PROMPT
  
  # Call amp with the prompt
  puts "Calling Amp..."
  
  # Create a temporary file with the prompt
  temp_prompt_file = File.join(Dir.tmpdir, "amp_prompt_#{basename}.txt")
  File.write(temp_prompt_file, prompt)
  
  # Call amp and capture output
  output, status = Open3.capture2("amp", "-x", prompt)
  
  if status.success?
    # Extract only the Ruby code between FactoryBot.define and final end
    ruby_code = output[/FactoryBot\.define do.*\nend\s*\z/m]
    
    if ruby_code
      File.write(rb_file, ruby_code)
      puts "✅ Created #{rb_file}"
    else
      # Try to extract from markdown code block if present
      if output =~ /```ruby\n(.*?)```/m
        ruby_code = $1.strip
        File.write(rb_file, ruby_code)
        puts "✅ Created #{rb_file} (extracted from markdown)"
      else
        puts "❌ Could not extract Ruby code from output for #{basename}"
        puts "Raw output:\n#{output[0..500]}"
      end
    end
  else
    puts "❌ Failed to convert #{basename}: #{output}"
  end
  
  # Clean up temp file
  FileUtils.rm_f(temp_prompt_file)
end

puts "\n✅ Conversion complete!"
puts "\nNext steps:"
puts "1. Review the generated factory files in test/factories/"
puts "2. Run tests to verify the factories work correctly"
