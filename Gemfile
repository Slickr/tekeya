source 'https://rubygems.org'

gemspec

group :development do
  gem "rails"     , "~> 3.2.6"
  gem 'debugger'  , '~> 1.2.0'
  gem 'yard'      , '~> 0.8.2.1'
  gem 'bluecloth'
end

group :test do
  gem 'rspec'             , '~> 2.11.0'
  gem 'mongoid-rspec'     , '~> 1.5.4'
  gem 'database_cleaner'  , '~> 0.8.0'
end

platforms :jruby do
  gem "activerecord-jdbc-adapter"
  gem "activerecord-jdbcsqlite3-adapter"
  gem "jruby-openssl"
end

platforms :ruby do
  gem "sqlite3"

  group :mongoid do
    gem "mongo", "~> 1.7.0"
    gem "mongoid", "~> 3.0"
    gem "bson_ext", "~> 1.7.0"
  end
end
