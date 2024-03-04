# syntax=docker/dockerfile:1-labs
FROM public.ecr.aws/docker/library/alpine:3.19 AS base
ENV TZ=UTC
WORKDIR /src

# dependencies shared between build and run
RUN apk add --no-cache \
    py3-chardet \
    py3-distro \
    py3-libtorrent-rasterbar \
    py3-mako \
    py3-openssl \
    py3-pillow \
    py3-rencode \
    py3-setproctitle \
    py3-twisted \
    py3-xdg

# source stage =================================================================
FROM base AS source

# get and extract source from git
ARG BRANCH
ARG VERSION
ADD https://github.com/deluge-torrent/deluge.git#${BRANCH:-deluge-$VERSION} ./

# deluge versioning
RUN echo "$VERSION" > RELEASE-VERSION

# backend stage ================================================================
FROM base AS build-backend

# dependencies
RUN apk add --no-cache py3-wheel py3-gpep517 py3-rjsmin

# copy source
COPY --from=source /src/deluge ./deluge
COPY --from=source /src/docs ./docs
COPY --from=source /src/RELEASE-VERSION /src/README.md /src/MANIFEST.in /src/setup.cfg /src/*.py ./

# build
RUN gpep517 build-wheel --wheel-dir /build --output-fd 3 3>&1 >&2

# runtime stage ================================================================
FROM base

ENV S6_VERBOSITY=0 S6_BEHAVIOUR_IF_STAGE2_FAILS=2 PUID=65534 PGID=65534
ENV ENV="/root/.profile" HOME="/config"
WORKDIR /config
VOLUME /config
EXPOSE 8080

# copy files
COPY --from=build-backend /build /build
COPY ./rootfs/. /

# install python wheel
RUN apk add --no-cache py3-installer && \
    python3 -m installer /build/deluge* && \
    apk del py3-installer && rm -rf /build

# runtime dependencies
RUN apk add --no-cache tzdata s6-overlay iptables wireguard-tools curl

# run using s6-overlay
ENTRYPOINT ["/init"]
