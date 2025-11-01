# Dockerfile for testing jsonapi-resources with multiple Rails versions
FROM ruby:3.2

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libsqlite3-dev nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy gemspec and Gemfile first for better caching
COPY jsonapi-resources.gemspec Gemfile ./
COPY lib/jsonapi/resources/version.rb ./lib/jsonapi/resources/

# Install bundler
RUN gem install bundler

# Set default Rails version (can be overridden via build arg or env var)
ARG RAILS_VERSION=6.1.7.10
ENV RAILS_VERSION=${RAILS_VERSION}

# Install dependencies
RUN bundle install

# Copy the rest of the application
COPY . .

# Default command runs tests
CMD ["bundle", "exec", "rake", "test"]
