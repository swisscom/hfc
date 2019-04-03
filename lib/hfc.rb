# frozen_string_literal: true

require 'hfc/version'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/object/deep_dup'
require 'yaml'
require 'json'

module HFC_Base
  class Error < StandardError; end

  attr_accessor :config
  attr_accessor :lookup_paths

  DEFAULT_LOOKUP_PATHS = ['/opt/hfc', File.join(ENV['HOME'].to_s, '.config', 'hfc')]
  def initialize(lookup_paths: ENV['HFC'] ? ENV['HFC'].split(',') : DEFAULT_LOOKUP_PATHS, config: ::ActiveSupport::HashWithIndifferentAccess.new, auto_lookup: true)
    @config = ::ActiveSupport::HashWithIndifferentAccess.new(config)
    @lookup_paths = lookup_paths
    lookup if auto_lookup
  end

  def by_file(file)
    case File.extname file
    when '.rb'
      deep_merge(eval(IO.read(file), binding, file))
    when '.yaml', '.yml'
      deep_merge(::YAML.load(::File.read(file)))
    when '.json'
      deep_merge(::JSON.parse(::File.read(file)))
    end
  end

  def to_h
    config
  end

  def deep_merge(hash)
    config.deep_merge!(hash)
  end

  def deep_dup
    self.class.new(lookup_paths: lookup_paths, config: config.deep_dup)
  end
  alias deep_dup clone

  def set(*args, value:)
    last = args.pop
    all_conf = conf = ::ActiveSupport::HashWithIndifferentAccess.new
    args.each do |arg|
      conf[arg] = ::ActiveSupport::HashWithIndifferentAccess.new unless conf[arg].is_a?(Hash)
      conf = conf[arg]
    end
    conf[last] = value
    deep_merge(all_conf)
  end

  def fetch(*args, default: nil)
    conf = config
    last = args.pop
    args.each do |arg|
      next unless conf[arg].is_a?(Hash)

      conf = conf[arg]
    end
    return default unless conf.is_a?(Hash)
    conf[last] || default
  end


  def lookup(facts: ::ActiveSupport::HashWithIndifferentAccess.new)
    facts = ::ActiveSupport::HashWithIndifferentAccess.new facts
    facts = facts.each_with_object(::ActiveSupport::HashWithIndifferentAccess.new) { |(key, value), hash| hash[key.to_s.downcase] = value.to_s.downcase }
    STDERR.puts "-> #{facts.inspect}" if $VERBOSE
    lookup_paths.each do |base|
      STDERR.puts "-> #{base}" if $VERBOSE
      Dir.glob(File.join(base, 'common.*')).sort.each do |file|
        STDERR.puts "--> #{file}" if $VERBOSE
        by_file(file)
      end

      fetch(:hfc, :facts, :hierarchy, default: []).each do |key|
        key = key.to_s.downcase
        value = facts[key]
        next unless value

        STDERR.puts "---> #{File.join(base, key, value + '.*')}" if $VERBOSE
        Dir.glob(File.join(base, key, value + '.*')).sort.each do |file|
          STDERR.puts "---> #{file}" if $VERBOSE
          by_file(file)
        end
      end
    end
    config
  end

  def facts_by_name(name)
    name = name.downcase
    facts = ::ActiveSupport::HashWithIndifferentAccess.new(name: name)
    fetch(:hfc, :facts, :by_name, default: {}).each do |_key, regex|
      if name[regex]
        facts.merge!(name.match(regex).named_captures.map { |k, v| [k.to_sym, v] }.to_h)
      end
    end

    fetch(:hfc, :facts, :join_facts, default: {}).each do |key, keys|
      facts[key] = keys.map { |a_key| facts[a_key] }.map(&:to_s).join('-')
    end

    fetch(:hfc, :facts, :by_facts, default: {}).each do |when_fact, target_fact_values|
      target_fact_values.each do |target_fact, values|
        next unless facts[when_fact] == target_fact

        values.each do |key, value|
          facts[key] = value
        end
      end
    end
    facts
  end

end

class HFC
  include HFC_Base

  def self.facts_by_name(name)
    HFC.new.facts_by_name(name)
  end

  def self.fetch(*args)
    HFC.new.fetch(*args)
  end

  def self.lookup(facts: ::ActiveSupport::HashWithIndifferentAccess.new)
    HFC.new.lookup(facts: facts)
  end
end
