# Baikal (sabre-io/Baikal) on PHP-FPM + nginx.
# BAIKAL_VERSION is set by the workflow to the upstream release tag (e.g. 0.12.1).
ARG PHP_VERSION=8.4

FROM alpine:3 AS download
ARG BAIKAL_VERSION
RUN test -n "$BAIKAL_VERSION" \
 && apk add --no-cache curl unzip \
 && curl -fsSL -o /baikal.zip "https://github.com/sabre-io/Baikal/releases/download/${BAIKAL_VERSION}/baikal-${BAIKAL_VERSION}.zip" \
 && unzip -q /baikal.zip -d / \
 && grep -q "\"${BAIKAL_VERSION}\"" /baikal/Core/Distrib.php

FROM php:${PHP_VERSION}-fpm-bookworm

# sqlite, mbstring, xml/xmlreader, curl are built into the base image;
# pdo_mysql/pdo_pgsql are added so MySQL/PostgreSQL backends work too.
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx curl libpq-dev \
 && docker-php-ext-install -j"$(nproc)" pdo_mysql pdo_pgsql \
 && apt-get purge -y libpq-dev && apt-get install -y --no-install-recommends libpq5 \
 && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/nginx/sites-enabled/default \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log

COPY rootfs/ /
COPY --from=download --chown=www-data:www-data /baikal /var/www/baikal

ARG BAIKAL_VERSION
LABEL org.opencontainers.image.title="Baikal" \
      org.opencontainers.image.description="Baikal CalDAV/CardDAV server (sabre-io/Baikal) on PHP-FPM + nginx" \
      org.opencontainers.image.version="${BAIKAL_VERSION}"

ENV TZ=UTC
VOLUME ["/var/www/baikal/config", "/var/www/baikal/Specific"]
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS -o /dev/null http://127.0.0.1/healthz || exit 1

STOPSIGNAL SIGQUIT
ENTRYPOINT ["/usr/local/bin/baikal-entrypoint"]
CMD ["nginx", "-g", "daemon off;"]
