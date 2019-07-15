# frozen_string_literal: true

require 'hfc/version'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/object/deep_dup'
require 'yaml'
require 'json'

module HFC_Base
  class Error < StandardError; end

  attr_accessor :config, :facts
  attr_accessor :lookup_paths

  def initialize(lookup_paths: ENV['HFC'] ? ENV['HFC'].split(',') : ['/opt/hfc', File.join(ENV['HOME'].to_s, '.config', 'hfc')], config: ::ActiveSupport::HashWithIndifferentAccess.new, auto_lookup: true, facts: ActiveSupport::HashWithIndifferentAccess.new)
    self.config = ::ActiveSupport::HashWithIndifferentAccess.new(config)
    self.facts = ActiveSupport::HashWithIndifferentAccess.new(facts)
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
    self.config = config.deep_merge(hash)
    config
  end

  def deep_dup
    self.class.new(lookup_paths: lookup_paths, config: config.deep_dup, facts: facts.clone)
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
  alias [] fetch

  def lookup(facts: nil)
    lookup_facts = ::ActiveSupport::HashWithIndifferentAccess.new facts || Hash.new
    lookup_facts = lookup_facts.each_with_object(::ActiveSupport::HashWithIndifferentAccess.new) { |(key, value), hash| hash[key.to_s.downcase] = value.to_s.downcase }
    STDERR.puts "-> #{lookup_facts.inspect}" if $VERBOSE
    lookup_paths.each do |base|
      STDERR.puts "-> #{base}" if $VERBOSE
      Dir.glob(File.join(base, 'common.*')).sort.each do |file|
        STDERR.puts "--> #{file}" if $VERBOSE
        by_file(file)
      end

      fetch(:hfc, :facts, :hierarchy, default: []).each do |key|
        key = key.to_s.downcase
        value = lookup_facts[key]
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
    name_facts = ::ActiveSupport::HashWithIndifferentAccess.new(name: name)
    fetch(:hfc, :facts, :by_name, default: Hash.new).each do |_key, regex|
      if name[regex]
        name_facts.merge!(name.match(regex).named_captures.map { |k, v| [k.to_sym, v] }.to_h)
      end
    end

    fetch(:hfc, :facts, :join_facts, default: Hash.new).each do |key, keys|
      name_facts[key] = keys.map { |a_key| name_facts[a_key] }.map(&:to_s).join('-')
    end

    fetch(:hfc, :facts, :by_facts, default: Hash.new).each do |when_fact, target_fact_values|
      target_fact_values.each do |target_fact, values|
        next unless name_facts[when_fact] == target_fact

        values.each do |key, value|
          name_facts[key] = value
        end
      end
    end
    name_facts
  end

  def set_facts_by_name(name)
    self.facts = facts_by_name(name)
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
