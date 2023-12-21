#!/bin/sh
set -e

export BUILD_STAMP=$(cd ./pulumi-service && date -u '+%Y-%m-%d_%I:%M:%S%p')
export BUILD_GIT_HASH=$(cd ./pulumi-service && git rev-parse HEAD)

goreleaser release --clean
