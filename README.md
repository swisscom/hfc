# (H)ierarchical(F)acts(C)onfig

## Installation


### Gem
Add this line to your application's Gemfile:

```ruby
gem 'hfc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hfc


### config

download the example config from the "config" directory and store it at /opt/hfc/ or set ``env HFC=/my/path

Setup the hierarchy according to your preference and start generating the config based on the facts you give it.

### Supported extensions

 - .rb
 - .yaml
 - .yml
 - .json

### Versioning

You can either version your own config folder using git or you can gemify it:

```
bundle exec gem Company-Config
```

```ruby
# company-config/lib/company/config.rb 
require 'hfc'
module Company
  module Config
    def self.dir
      File.join(__dir__,"..","..","hfc")
    end
    Dir = File.join(__dir__,"..","..","hfc")
  end

  class HFC
    include ::HFC_Base
    def initialize(lookup_paths: [::Company::Config::Dir, File.join(ENV['HOME'].to_s, '.config', 'hfc')], **opts)
      super(lookup_paths: lookup_paths, **opts)
    end
  end
end
```
 
```ruby
require 'company/config' 
company_hfc = Company::Config.new
```

Now you have your own config gem which includes your config data. You can version it and include it in any project.
The biggest advantage is the semantic versioningi. You can declare now breaking changes of your config.

## Idea

(H)ierarchical (F)acts (C)onfiguration

### Facts

In HFC, the facts decide which files get deep-merged into one giant configuration. For every Fact it will try to find the corresponding file in the fact-folder.

No facts: 
```
|
|- {}
|- merge: config/common.(yaml|rb|*)
|- {...}
```

Facts: {domain: "com"}
```
|
|- {}
|- merge: common.(yaml|rb|*)
|- merge: domain/com.(yaml|rb|*) 
|- {...}
```

Facts: {hostname: "localhost", domain: "com"}
```
|
|- {}
|- merge: common.(yaml|rb|*)
|- merge: domain/com.(yaml|rb|*)
|- merge: hostname/localhost(yaml|rb|*) 
|- {...}
```

You can build up this hierarchy of facts with as many facts as you wish.

### Facts Hierachy

The lookup order of facts itself is defined on common.yaml, but can be also set anywhere else.

See `config/common.yaml` for example.

```yaml
---
hfc:
  hierarchy:
    - :domain
    - :hostname
```

### Facts by name

Facts can also be extracted by using named matches of a regex.

```yaml
hfc:
  by_name:
    hostname:  !ruby/regexp '/(?<fqdn>(?<hostname>[a-z0-9]+)\.?(?<domain>.*))/i'
```

```ruby
facts = HFC.facts_by_name("gitlab.com")
# => {fqdn: "gitlab.com", hostname: "gitlab", domain: "com"}
```

### Join Facts

It's also possible to join facts to create a new fact.

```yaml
hfc:
  join_facts:
    reverse-hostname:
      - :domain
      - :hostname
```

```
reverse-hostname = "#{domain}-#{hostname}"
```

### Facts by Facts

Facts can also create new facts

```yaml
hfc:
  by_facts:
    fqdn:
      "127.0.0.1":
        hostname: "localhost"
```

If the fact "fqdn" equals to "127.0.0.1", then the fact "hostname" will be set to "localhost"

## Usage

```
hfc  --name gitlab.com
```

```ruby
facts = HFC.facts_by_name("gitlab.com")
config = HFC.lookup(facts)
```

### HFC#fetch

```ruby
facts = HFC.facts_by_name("127.0.0.1")
config = HFC.lookup(facts: facts)
config.fetch()
# => {my: {nested: {setting: true}}}
config.fetch(:my)
# => {nested: {setting: true}}
config.fetch(:my, "nested")
# => {setting: true}
config.fetch(:my, :nested, :setting)
# => true
```
### HFC#fetch uses internally HashWithIndifferentAccess

```ruby
config.fetch(:my, "nested")
# => {setting: true}
```
```ruby
config.fetch(:my, :nested)
# => {setting: true}
```

### HFC#[]

hfc#`[]` is an alias of hfc#`fetch`

```ruby
config[:my, :nested]
# => {setting: true}
```


## Why not use ___ ?

This gem is inspired by
 - hiera https://github.com/puppetlabs/hiera
 - tty-config https://github.com/piotrmurach/tty-config

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/swisscom/hfc.
