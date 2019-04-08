FROM frolvlad/alpine-gcc

RUN apk add --no-cache ghc curl

RUN curl -L https://github.com/nh2/stack/releases/download/v1.6.5/stack-prerelease-1.9.0.1-x86_64-unofficial-fully-static-musl > /usr/bin/stack

RUN chmod +x /usr/bin/stack
