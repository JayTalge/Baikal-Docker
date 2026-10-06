# Baikal-Docker

Docker image for [sabre-io/Baikal](https://github.com/sabre-io/Baikal) (CalDAV/CardDAV server), built from the official release zip. This repo contains only the Dockerfile, the nginx/PHP-FPM config and a build workflow. The upstream code is not forked.

| Image | Tags |
|---|---|
| `ghcr.io/jaytalge/baikal` | `<version>` (e.g. `0.12.1`), `<minor>` (e.g. `0.12`), `latest` |

Base: `php:8.4-fpm-bookworm` + nginx from Debian. Extensions: pdo_sqlite, pdo_mysql, pdo_pgsql, mbstring, xml, curl.

## Build

- Every day at 03:37 UTC the workflow checks for the latest upstream **release tag**. It builds only if that tag is not in GHCR yet. It never builds `master`.
- Before pushing, the image is smoke-tested (`/healthz`, install page, Baikal version in `Core/Distrib.php`).
- To build manually, use Actions → "Build image from upstream release" → Run workflow. You can enter a specific tag and choose "force".
- A push to `Dockerfile`, `rootfs/` or the workflow rebuilds the current release (picks up a new PHP base image too).

## Usage

```yaml
services:
  baikal:
    image: ghcr.io/jaytalge/baikal:latest
    restart: unless-stopped
    environment:
      TZ: Europe/Berlin
    volumes:
      - ./config:/var/www/baikal/config
      - ./data:/var/www/baikal/Specific
```

## Runtime notes

- Listens on port 80. `/healthz` returns 200 for health checks (used by the image `HEALTHCHECK`).
- `/.well-known/caldav` and `/.well-known/carddav` redirect relatively to `/dav.php`, so they keep the scheme and host of the reverse proxy.
- Behind a TLS-terminating reverse proxy, `X-Forwarded-Proto: https` is passed to PHP as `HTTPS=on` / port 443, so Baikal's own redirects use https.
- On start, `config/` and `Specific/` are chowned to `www-data`. That makes volumes from `ckulka/baikal` (uid 101) work. Set `BAIKAL_SKIP_CHOWN=1` to skip.
- After a version change, the container runs Baikal's upgrade wizard by itself (`baikal-auto-upgrade`), so CalDAV keeps working after an automatic update (e.g. Watchtower). Before that it copies the SQLite DB to `Specific/db/db.sqlite.pre-<version>`. Downgrades are never upgraded. Set `BAIKAL_AUTO_UPGRADE=false` to click the wizard at `/admin/install/` yourself.
- Not included compared to `ckulka/baikal`: msmtp for e-mail invitations and the Home Assistant patch.

Inspired by [ckulka/baikal-docker](https://github.com/ckulka/baikal-docker) (MIT).
