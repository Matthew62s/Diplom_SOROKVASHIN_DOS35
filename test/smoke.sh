#!/usr/bin/env bash
set -euo pipefail

image=${1:?Usage: bash tests/smoke.sh IMAGE}
tmp_dir=$(mktemp -d)
container_id=""

cleanup() {
  result=$?
  if [[ -n "$container_id" ]]; then
    if [[ "$result" -ne 0 ]]; then
      docker logs "$container_id" || true
    fi
    docker rm -f "$container_id" >/dev/null || true
  fi
  rm -rf "$tmp_dir"
  exit "$result"
}
trap cleanup EXIT

container_id=$(docker run --detach \
  --publish 127.0.0.1::8080 \
  --env HOSTNAME=goapp-smoke \
  --env POD_IP=10.0.0.2 \
  --env NODE_IP=172.31.10.1 \
  "$image")
address=$(docker port "$container_id" 8080/tcp)
base_url="http://$address"

curl --fail --silent --show-error \
  --retry 15 --retry-connrefused --retry-delay 1 \
  --retry-max-time 30 --max-time 3 \
  --dump-header "$tmp_dir/headers" \
  "$base_url/" > "$tmp_dir/root"

printf 'Hello, world!\nPod: goapp-smoke\nPod IP: 10.0.0.2\nNode IP: 172.31.10.1\n' \
  > "$tmp_dir/expected"
diff -u "$tmp_dir/expected" "$tmp_dir/root"
grep -iq '^Content-Type: text/plain; charset=utf-8' "$tmp_dir/headers"

curl --fail --silent --show-error --max-time 5 \
  "$base_url/metrics" > "$tmp_dir/metrics"
grep -q '^goapp_http_requests_total{code="200",method="get"} ' "$tmp_dir/metrics"
grep -q '^goapp_http_request_duration_seconds_count{method="get"} ' "$tmp_dir/metrics"
grep -q '^go_goroutines ' "$tmp_dir/metrics"

status=$(curl --silent --show-error --max-time 5 \
  --output /dev/null --write-out '%{http_code}' "$base_url/missing")
[[ "$status" == 404 ]]

echo 'Docker smoke test passed: /, /metrics, /missing'