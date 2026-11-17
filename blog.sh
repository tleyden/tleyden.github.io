#!/usr/bin/env bash
# Dockerized wrapper for this Octopress blog. Ruby/Jekyll live only in the
# octopress-blog image; git (and your GitHub credentials) stay on the host.
set -euo pipefail
cd "$(dirname "$0")"

IMAGE=octopress-blog
REPO_URL=$(git remote get-url origin)

TTY_FLAGS=-i
[ -t 0 ] && TTY_FLAGS=-it

run() {
  docker run --rm $TTY_FLAGS -v "$PWD":/blog -w /blog ${PORTS:-} "$IMAGE" "$@"
}

# Build the image on first use
docker image inspect "$IMAGE" >/dev/null 2>&1 || [ "${1:-}" = image ] || docker build -t "$IMAGE" .

case "${1:-}" in
  image)
    docker build -t "$IMAGE" .
    ;;
  shell)
    run bash
    ;;
  new)
    shift
    [ $# -ge 1 ] || { echo "usage: $0 new \"Post title\""; exit 1; }
    run bundle exec rake "new_post[$*]"
    ;;
  preview)
    PORTS="-p 4001:4001" run bundle exec rake preview
    ;;
  generate)
    run bundle exec rake generate
    ;;
  deploy)
    # Generate in Docker, then copy public/ into _deploy (a checkout of the
    # master branch) and push from the host.
    run bundle exec rake generate
    if [ ! -d _deploy/.git ]; then
      git clone --branch master --single-branch "$REPO_URL" _deploy
    fi
    git -C _deploy pull --ff-only
    find _deploy -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
    cp -R public/. _deploy/
    git -C _deploy add -A
    git -C _deploy commit -m "Site updated at $(date -u '+%Y-%m-%d %H:%M:%S UTC')" || echo "Nothing to deploy"
    git -C _deploy push origin master
    ;;
  *)
    echo "usage: $0 {image|new \"title\"|preview|generate|deploy|shell}"
    exit 1
    ;;
esac
