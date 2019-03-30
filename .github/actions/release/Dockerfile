FROM alpine:latest

LABEL "com.github.actions.name"="GitHub Release"
LABEL "com.github.actions.description"="Create a GitHub release"
LABEL "com.github.actions.icon"="command"
LABEL "com.github.actions.color"="blue"
LABEL "maintainer"="Loren Segal <lsegal@soen.ca>"

RUN apk add --no-cache -U \
  --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
  hub git ruby

WORKDIR /github/workspace
COPY ./entrypoint.rb /entrypoint.rb
RUN chmod +x /entrypoint.rb
ENTRYPOINT [ "/entrypoint.rb" ]
