# Build environment for this 2013-era Octopress blog (Jekyll 0.12).
# Ruby 2.3 because yajl-ruby 1.1.0 (pinned by pygments.rb 0.3.x) uses
# rb_cFixnum, removed in Ruby 2.4. pygments.rb also needs Python 2.
FROM ruby:2.3-stretch
RUN sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g; /stretch-updates/d' /etc/apt/sources.list \
 && apt-get update && apt-get install -y --no-install-recommends python \
 && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -v 1.16.6
WORKDIR /blog
COPY Gemfile Gemfile.lock ./
RUN bundle _1.16.6_ install
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=America/Los_Angeles
