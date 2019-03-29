FROM ruby:2

WORKDIR /github/workspace
COPY ./entrypoint.rb /entrypoint.rb
RUN chmod +x /entrypoint.rb
ENTRYPOINT [ "/entrypoint.rb" ]
