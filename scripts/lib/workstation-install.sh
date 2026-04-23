#!/usr/bin/env bash

resolve_repo_root() {
  local script_dir="$1"
  if [[ "$script_dir" == /nix/store/* ]]; then
    printf '%s\n' "$PWD"
  else
    cd "$script_dir/.." && pwd
  fi
}

list_hosts() {
  local hosts_dir="$1/targets/hosts"
  if [[ ! -d "$hosts_dir" ]]; then
    return 0
  fi

  local first=1
  local host
  while IFS= read -r host; do
    [[ -z "$host" ]] && continue
    if [[ $first -eq 1 ]]; then
      printf '%s' "$host"
      first=0
    else
      printf ' %s' "$host"
    fi
  done < <(find "$hosts_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
  printf '\n'
}

read_nix_string_var() {
  local file="$1"
  local key="$2"

  if [[ ! -f "$file" ]]; then
    return 0
  fi

  sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"([^\"]+)\";.*$/\\1/p" "$file" | head -1
}

host_vars_file() {
  printf '%s/targets/hosts/%s/vars.nix\n' "$1" "$2"
}

host_default_file() {
  printf '%s/targets/hosts/%s/default.nix\n' "$1" "$2"
}

host_disko_file() {
  printf '%s/targets/hosts/%s/disko.nix\n' "$1" "$2"
}

home_target_file() {
  printf '%s/home/targets/%s.nix\n' "$1" "$2"
}

host_exists() {
  local repo_root="$1"
  local host="$2"
  [[ -d "$repo_root/targets/hosts/$host" ]]
}

host_has_profile() {
  local repo_root="$1"
  local host="$2"
  local profile="$3"
  local host_dir="$repo_root/targets/hosts/$host"

  [[ -d "$host_dir" ]] && grep -R -q "modules/profiles/${profile}.nix" "$host_dir"
}

host_is_virtual_machine() {
  local repo_root="$1"
  local host="$2"
  host_has_profile "$repo_root" "$host" "virtual-machine"
}

host_machine_context() {
  local repo_root="$1"
  local host="$2"
  if host_is_virtual_machine "$repo_root" "$host"; then
    printf 'virtual-machine\n'
  else
    printf 'bare-metal\n'
  fi
}

host_uses_disko() {
  local repo_root="$1"
  local host="$2"
  [[ -f "$(host_disko_file "$repo_root" "$host")" ]]
}

host_exposed_in_flake() {
  local repo_root="$1"
  local host="$2"
  grep -qE "^[[:space:]]*${host}[[:space:]]*=[[:space:]]*mkHost" "$repo_root/flake.nix"
}

flake_exposes_app() {
  local repo_root="$1"
  local app_name="$2"
  grep -qE "^[[:space:]]*${app_name}[[:space:]]*=[[:space:]]*mkApp" "$repo_root/flake.nix"
}

flake_host_uses_disko_module() {
  local repo_root="$1"
  local host="$2"

  awk -v host="$host" '
    $0 ~ "^[[:space:]]*" host "[[:space:]]*=[[:space:]]*mkHost[[:space:]]*\\{" { in_host = 1 }
    in_host { print }
    in_host && /^[[:space:]]*};[[:space:]]*$/ { exit }
  ' "$repo_root/flake.nix" | grep -q 'disko\.nixosModules\.disko'
}

collect_active_dotfiles() {
  local home_file="$1"

  if [[ ! -f "$home_file" ]]; then
    return 0
  fi

  sed -nE 's/^[[:space:]]*([[:alnum:]_.-]+\.)?"[^"]+"[.]source[[:space:]]*=[[:space:]]*(lib\.mkForce[[:space:]]+)?(\.\.\/)+dotfiles\/([^;[:space:]]+);[[:space:]]*$/\4/p' "$home_file"
}

collect_home_file_mappings() {
  local home_file="$1"

  if [[ ! -f "$home_file" ]]; then
    return 0
  fi

  sed -nE 's/^[[:space:]]*([[:alnum:]_.-]+\.)?"([^"]+)"[.]source[[:space:]]*=[[:space:]]*(lib\.mkForce[[:space:]]+)?(\.\.\/)+dotfiles\/([^;[:space:]]+);[[:space:]]*$/\2|\5/p' "$home_file"
}

collect_imported_nix_paths() {
  local nix_file="$1"

  if [[ ! -f "$nix_file" ]]; then
    return 0
  fi

  grep -oE '(\.\.?/[^[:space:];]+\.nix)' "$nix_file" || true
}

collect_target_user_imports() {
  local target_file="$1"
  local user="$2"

  if [[ ! -f "$target_file" ]]; then
    return 0
  fi

  awk -v user="$user" '
    $0 ~ "^[[:space:]]*" user "[[:space:]]*=[[:space:]]*\\{" { in_user = 1; next }
    in_user && $0 ~ "^[[:space:]]*\\};[[:space:]]*$" { in_user = 0; next }
    in_user {
      while (match($0, /(\.\.?\/[^[:space:];]+\.nix)/, m)) {
        print m[1]
        $0 = substr($0, RSTART + RLENGTH)
      }
    }
  ' "$target_file"
}

declare -gA __home_nix_visited=()

_collect_home_nix_tree_recursive() {
  local entry="$1"
  local resolved
  resolved="$(realpath -m "$entry")"

  [[ -f "$resolved" ]] || return 0
  if [[ -n "${__home_nix_visited[$resolved]:-}" ]]; then
    return 0
  fi
  __home_nix_visited["$resolved"]=1

  while IFS= read -r rel_import; do
    [[ -z "$rel_import" ]] && continue
    _collect_home_nix_tree_recursive "$(dirname "$resolved")/$rel_import"
  done < <(collect_imported_nix_paths "$resolved")

  printf '%s\n' "$resolved"
}

list_home_nix_files_for_host() {
  local repo_root="$1"
  local host="$2"
  local target_file
  target_file="$(home_target_file "$repo_root" "$host")"

  __home_nix_visited=()
  if [[ -f "$target_file" ]]; then
    _collect_home_nix_tree_recursive "$target_file"
  fi
}

list_home_nix_files_for_host_user() {
  local repo_root="$1"
  local host="$2"
  local user="$3"
  local target_file
  target_file="$(home_target_file "$repo_root" "$host")"

  __home_nix_visited=()
  if [[ -f "$target_file" ]]; then
    local found=0
    while IFS= read -r rel_import; do
      [[ -z "$rel_import" ]] && continue
      found=1
      _collect_home_nix_tree_recursive "$(dirname "$target_file")/$rel_import"
    done < <(collect_target_user_imports "$target_file" "$user")

    if [[ $found -eq 1 ]]; then
      return 0
    fi
  fi
}

collect_active_dotfiles_for_host() {
  local repo_root="$1"
  local host="$2"

  while IFS= read -r nix_file; do
    [[ -z "$nix_file" ]] && continue
    collect_active_dotfiles "$nix_file"
  done < <(list_home_nix_files_for_host "$repo_root" "$host") | sort -u
}

collect_home_file_mappings_for_host_user() {
  local repo_root="$1"
  local host="$2"
  local user="$3"

  while IFS= read -r nix_file; do
    [[ -z "$nix_file" ]] && continue
    collect_home_file_mappings "$nix_file"
  done < <(list_home_nix_files_for_host_user "$repo_root" "$host" "$user") | awk -F'|' '!seen[$1]++'
}

is_placeholder_value() {
  local value="${1:-}"
  [[ "$value" =~ ^DEFINE_ ]] || [[ "$value" == "/dev/DEFINE_DISK" ]] || [[ "$value" == "CHANGEME" ]]
}

is_supported_nixos_system() {
  local value="${1:-}"
  [[ "$value" == "x86_64-linux" || "$value" == "aarch64-linux" ]]
}
