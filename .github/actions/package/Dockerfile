FROM ruby:2
ENV BUNDLE_PATH=/github/home/.bundle
ENTRYPOINT sh -c "bundle exec rake gem && bundle exec rake install"
