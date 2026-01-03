# Makefile for Jekyll blog

# Variables
JEKYLL_ENV := "development"

# Default task
all: help

# Help
help:
	@echo "Usage: make [command]"
	@echo "Commands:"
	@echo "  install    - Install dependencies"
	@echo "  serve      - Serve the blog locally"
	@echo "  build      - Build the blog for production"
	@echo "  test       - Run tests"

# Install dependencies
install:
	@echo "Installing dependencies..."
	@bundle install

# Serve the blog locally
serve:
	@echo "Starting Jekyll server..."
	@bundle exec jekyll serve

# Build the blog for production
build:
	@echo "Building the blog for production..."
	@JEKYLL_ENV=production bundle exec jekyll b -d "_site"

# Run tests
test:
	@echo "Running tests..."
	@bundle exec htmlproofer _site --disable-external --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/"

.PHONY: all help install serve build test
