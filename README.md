# Fifatum

## Development environment setup

### Elm

The client application is programmed in [Elm](http://elm-lang.org/) v0.18.0. To install the compiler simply run:

```
$ npm install elm@0.18.0
```

### Rails

The app uses Ruby 2.3.1. To install Rails and other Ruby dependencies using Bundler, run:

```
$ gem install bundler
$ bundle install --path=.bundle
```

### Database

By default, the application tries to connect to a postgres server at localhost:5432. The database can be created using [Docker compose](https://docs.docker.com/compose/) as follows:

```
$ docker-compose up -d
```

After that, run migrations and import FIFA17 teams with the following commands:

```
$ bundle exec rake db:setup
```

To download and import FIFA17 teams:

```
$ bin/scraper
$ bin/import_teams
```

### Testing

To run de test suite simply run

```
$ bundle exec rspec
```
