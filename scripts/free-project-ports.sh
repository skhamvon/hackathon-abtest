#!/usr/bin/env bash
# Arrête les processus en écoute sur les ports du hackathon (défauts : abtest-docs → reference/ports-and-env).
set -u
PORTS=(5000 5001 5002 5101 5173 5174 5175)

pids_lsof() {
  local port
  for port in "${PORTS[@]}"; do
    lsof -t -iTCP:"$port" -sTCP:LISTEN 2>/dev/null || true
  done | sort -u -n
}

pids_ss() {
  local port line
  for port in "${PORTS[@]}"; do
    while IFS= read -r line; do
      [[ "$line" =~ pid=([0-9]+) ]] && echo "${BASH_REMATCH[1]}"
    done < <(
      ss -tlnp 2>/dev/null | awk -v p="$port" 'NR > 1 && /LISTEN/ && $4 ~ ":" p "$"' || true
    )
  done | sort -u -n
}

collect_pids() {
  if command -v lsof >/dev/null 2>&1; then
    pids_lsof
  else
    pids_ss
  fi
}

if ! command -v lsof >/dev/null 2>&1; then
  if ! ss -tlnp &>/dev/null; then
    echo "free-project-ports: installez le paquet lsof ou iproute2 (ss)." >&2
    exit 1
  fi
fi

# Optionnel : fuser (paquet psmisc) complète lsof/ss sur certaines distros.
if command -v fuser >/dev/null 2>&1; then
  for port in "${PORTS[@]}"; do
    fuser -k -TERM "$port/tcp" 2>/dev/null || true
  done
  sleep 1
  for port in "${PORTS[@]}"; do
    fuser -k -KILL "$port/tcp" 2>/dev/null || true
  done
  sleep 0.5
fi

mapfile -t PIDS < <(collect_pids)
if ((${#PIDS[@]} == 0)); then
  echo "free-project-ports: aucun listener sur ${PORTS[*]}."
  exit 0
fi

echo "free-project-ports: arrêt (SIGTERM) des PID: ${PIDS[*]}"
for p in "${PIDS[@]}"; do
  [[ -z "$p" ]] && continue
  kill -TERM "$p" 2>/dev/null || true
done
sleep 1

mapfile -t STILL < <(collect_pids)
if ((${#STILL[@]} > 0)); then
  echo "free-project-ports: encore actifs → SIGKILL: ${STILL[*]}"
  for p in "${STILL[@]}"; do
    [[ -z "$p" ]] && continue
    kill -KILL "$p" 2>/dev/null || true
  done
  sleep 0.5
fi

mapfile -t LEFT < <(collect_pids)
if ((${#LEFT[@]} > 0)); then
  echo "free-project-ports: échec partiel (droits ou PID invisibles): ${LEFT[*]}" >&2
  exit 1
fi

echo "free-project-ports: terminé."
