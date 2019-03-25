# HFC

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

### Supported

 - .rb
 - .yaml
 - .yml
 - .json

## Usage

```
hfc  --name gitlab.com
```

```ruby
facts = HFC.facts_by_name("gitlab.com")
config = HFC.lookup(facts)
```

```ruby
facts = HFC.facts_by_name("127.0.0.1")
config = HFC.lookup(facts: facts)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hfc.
