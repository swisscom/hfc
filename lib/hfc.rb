# frozen_string_literal: true

require 'hfc/version'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/deep_merge'
require 'yaml'
require 'json'

module HFC
  class Error < StandardError; end

  LOOKUP_PATHS = ENV['HFC'] ? ENV['HFC'].split(',') : ['/opt/hfc', File.join(ENV['HOME'].to_s, '.config', 'hfc')]

  class Config
    attr_accessor :config
    def initialize()
      @config = ::ActiveSupport::HashWithIndifferentAccess.new 
    end

    def by_file(file)
      case File.extname file
      when ".rb"
        deep_merge(eval(IO.read(file), binding, file))
      when ".yaml", ".yml"
        deep_merge(::YAML.load(::File.read(file)))
      when ".json"
        deep_merge(::JSON.parse(::File.read(file)))
      end
    end

    def to_h
      config.to_h
    end

    def deep_merge(hash)
      config.deep_merge!(hash)
    end

    def set(*args, value: )
      last = args.shift
      conf = config
      args.each do |arg|
        conf[arg] = ::ActiveSupport::HashWithIndifferentAccess.new unless conf[arg].is_a?(Hash)
        conf = conf[arg]
      end
      conf[last] = value
      config
    end

    def fetch(*args)
      conf = config
      args.each do |arg|
        conf.is_a?(Hash) && conf.has_key?(arg) ? conf = conf[arg] : conf
      end
      conf
    end
  end

  def self.lookup(facts: ::ActiveSupport::HashWithIndifferentAccess.new)
    facts = ::ActiveSupport::HashWithIndifferentAccess.new facts
    facts = facts.each_with_object(::ActiveSupport::HashWithIndifferentAccess.new) { |(key, value), hash| hash[key.to_s.downcase] = value.to_s.downcase }
    config = Config.new
    STDERR.puts "-> #{facts.inspect}" if $VERBOSE
    LOOKUP_PATHS.each do |base|
      STDERR.puts "-> #{base}" if $VERBOSE
      Dir.glob(File.join(base, 'common.*')).sort.each do |file|
        STDERR.puts "--> #{file}" if $VERBOSE
        config.by_file(file)
      end

      config.fetch(:hfc, :facts, :hierarchy).each do |key|
        key = key.to_s.downcase
        value = facts[key]
        next unless value

        STDERR.puts "---> #{File.join(base, key, value + '.*')}" if $VERBOSE
        Dir.glob(File.join(base, key, value + '.*')).sort.each do |file|
          STDERR.puts "---> #{file}" if $VERBOSE
          config.by_file(file)
        end
      end
    end
    config
  end
  

  def self.facts_by_name(name, config: nil, **lookup_opts)
    config ||= lookup(**lookup_opts)
    name = name.downcase
    facts = { name: name }
    config.fetch(:hfc, :facts, :by_name).each do |key, regex|
      if name[regex]
        facts.merge!(name.match(regex).named_captures.map { |k, v| [k.to_sym, v] }.to_h)
      end
    end

    config.fetch(:hfc, :facts, :join_facts).each do |key, keys|
      facts[key] = keys.map {|a_key| facts[a_key]}.map(&:to_s).join("-")
    end

    config.fetch(:hfc, :facts, :by_facts).each do |when_fact, target_fact_values|
      target_fact_values.each do |target_fact, values|
        if facts[when_fact] == target_fact
          values.each do |key,value|
            facts[key] = value
          end
        end
      end
    end
    facts
  end
end
