#!/usr/bin/env bash
set -euo pipefail
TAG="${1:?Usage: bash scripts/deploy.sh <unique-tag>}"
[[ "$TAG" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,100}$ ]] || { echo 'Invalid image tag'; exit 1; }
IMAGE="docker.io/library/cicd-demo:$TAG"
COMMIT="$(git rev-parse --short=12 HEAD)"
BUILD="${BUILD_NUMBER:-manual}"
[[ "$BUILD" =~ ^[a-zA-Z0-9_.-]+$ ]] || exit 1
ARCHIVE="$(mktemp /tmp/cicd-demo.XXXXXX.tar)"
trap 'rm -f "$ARCHIVE"' EXIT
docker build --build-arg GIT_COMMIT="$COMMIT" --build-arg BUILD_NUMBER="$BUILD" --build-arg BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)" -t "$IMAGE" .
docker save "$IMAGE" -o "$ARCHIVE"
sudo -n k3s ctr -n k8s.io images import "$ARCHIVE"
sed "s|__IMAGE__|$IMAGE|g" k8s/deployment.yaml | sudo -n k3s kubectl apply -f -
sudo -n k3s kubectl rollout status deployment/cicd-demo -n demo --timeout=180s
EXPECTED="$(printf '{"commit":"%s","build":"%s"' "$COMMIT" "$BUILD")"
ACTUAL="$(curl --fail --silent --show-error --max-time 15 "http://192.168.200.100:30081/build.json")"
[[ "$ACTUAL" == "$EXPECTED"* ]] || { echo 'Smoke check failed: unexpected release'; exit 1; }
echo "Release verified: $IMAGE"
