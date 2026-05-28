# Docker container for use in project 1 - web application at Fontys Venlo

The container can be found at: [https://hub.docker.com/r/sebivenlo/prj1-web](https://hub.docker.com/r/sebivenlo/prj1-web)

This docker container is based on the official [php-apache](https://hub.docker.com/_/php) container.

The base container is extended with a couple of extensions that might be needed during the project.

## Variants

Two image variants are published from this repo. Both share the same PHP version, extensions, and `upload_max_filesize` / `post_max_size` so application code behaves identically in both.

| Tag                                     | Target | Use case                                                             |
| --------------------------------------- | ------ | -------------------------------------------------------------------- |
| `sebivenlo/prj1-web:<version>`          | `dev`  | Devcontainer / local development. Ships `git`, `gnupg`, `zip` CLI, a non-root `devuser` for UID/GID remapping, and `php.ini-development` (errors visible inline). |
| `sebivenlo/prj1-web:<version>-prod`     | `prod` | Deployments (e.g. the FontysVenlo developer platform). No dev tooling, no `devuser`, and `php.ini-production` (stack traces not shown in HTTP responses). |

Build a specific target locally:

```bash
docker build --target prod -t prj1-web:prod .
docker build --target dev  -t prj1-web:dev  .
```

`docker build .` (no `--target`) builds `dev`, matching the previous single-stage behaviour.

## Extensions:

- GD
- EXIF
- PDO
- PDO PostgreSQL
- ZIP

## Releasing a new version

There are two ways to release a new version to Docker Hub.

- Using git tags:
    1. Select the correct next version
    2. Create a git tag: `git tag -a v<version> -m "message"`
    3. Push the tag to GitHub: `git push origin <tag>`
- Create a release using the GitHub ui:
    1. Select the correct next version
    2. Click on `Releases` on the right
    3. Click `Create new release`
