#!/bin/sh

export GITHUB_TOKEN=${RELEASE_TOKEN:-$GITHUB_TOKEN}
export TAG=${GITHUB_REF#refs/tags/}

hub release create -a $ARTIFACT -F ${RELEASE_FILE:-/github/home/.releasenotes} $TAG
