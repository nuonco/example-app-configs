#!/usr/bin/env sh
# httpbin-healthcheck: probe an httpbin endpoint and report the result as
# action outputs. ENDPOINT is required; PATH_SUFFIX defaults to /status/200.
set -u

endpoint="${ENDPOINT:-}"
suffix="${PATH_SUFFIX:-/status/200}"

if [ -z "$endpoint" ]; then
  echo "httpbin-healthcheck: ENDPOINT is required" >&2
  exit 2
fi

case "$endpoint" in
http://* | https://*) ;;
*) endpoint="http://${endpoint}" ;;
esac

url="${endpoint}${suffix}"
echo "probing ${url}"

# nuon_output is installed on PATH by the actions supervisor. Fall back to a
# no-op so the image stays runnable outside a Nuon action.
emit() {
  if command -v nuon_output >/dev/null 2>&1; then
    nuon_output "$1" "$2"
  fi
  echo "  $1=$2"
}

status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo "000")
latency=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "$url" || echo "0")

emit status "$status"
emit latency_seconds "$latency"
emit url "$url"

if [ "$status" = "200" ]; then
  emit healthy "true"
  echo "✓ healthy"
  exit 0
fi

emit healthy "false"
echo "✗ unhealthy: expected 200, got ${status}" >&2
exit 1
