# Dockerfile for testing jsonapi-resources with multiple Rails versions

FROM ruby:3.2

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and gemspec
COPY Gemfile jsonapi-resources.gemspec ./
COPY lib/jsonapi/resources/version.rb ./lib/jsonapi/resources/

# Install bundler
RUN gem install bundler

# Note: bundle install will happen at runtime with specific RAILS_VERSION
# This allows testing multiple Rails versions without rebuilding the image
