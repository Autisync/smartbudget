#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

MODE="check"
ENV_FILE="${ROOT_DIR}/legal/placeholders.env"

usage() {
	cat <<'USAGE'
Usage: scripts/apply_legal_placeholders.sh [--check | --apply] [--env <path>]

Modes:
	--check        Validate env values and report unresolved placeholders (default)
	--apply        Replace placeholders in legal markdown files

Options:
	--env <path>   Path to env file with placeholder values
USAGE
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--check)
			MODE="check"
			shift
			;;
		--apply)
			MODE="apply"
			shift
			;;
		--env)
			if [[ $# -lt 2 ]]; then
				echo "error: --env requires a file path" >&2
				exit 1
			fi
			ENV_FILE="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "error: unknown argument '$1'" >&2
			usage >&2
			exit 1
			;;
	esac
done

if [[ ! -f "$ENV_FILE" ]]; then
	echo "error: env file not found: $ENV_FILE" >&2
	echo "hint: copy legal/placeholders.example.env to legal/placeholders.env" >&2
	exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

required_vars=(
	SUPPORT_EMAIL
	PRIVACY_EMAIL
	DPO_EMAIL_OR_CONTACT
	POSTAL_ADDRESS
	APP_STORE_URL_OR_WEBSITE
	ANALYTICS_PROVIDER
	ANALYTICS_PRIVACY_URL
)

missing=()
for var_name in "${required_vars[@]}"; do
	if [[ -z "${!var_name:-}" ]]; then
		missing+=("$var_name")
	fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
	echo "error: missing required values in $ENV_FILE:" >&2
	for name in "${missing[@]}"; do
		echo "  - $name" >&2
	done
	exit 1
fi

legal_docs=(
	"${ROOT_DIR}/legal/TERMS_OF_USE.md"
	"${ROOT_DIR}/legal/PRIVACY_POLICY.md"
	"${ROOT_DIR}/legal/COOKIES_AND_TRACKING_NOTICE.md"
	"${ROOT_DIR}/legal/ACCEPTABLE_USE_POLICY.md"
	"${ROOT_DIR}/legal/DATA_RETENTION_POLICY.md"
	"${ROOT_DIR}/legal/SECURITY_DISCLOSURE_POLICY.md"
	"${ROOT_DIR}/legal/THIRD_PARTY_SERVICES_NOTICE.md"
	"${ROOT_DIR}/legal/DISCLAIMERS.md"
)

for doc in "${legal_docs[@]}"; do
	if [[ ! -f "$doc" ]]; then
		echo "error: expected legal file missing: $doc" >&2
		exit 1
	fi
done

report_unresolved() {
	local count
	count=$(grep -hEo '\[[A-Z0-9_]+\]' "${legal_docs[@]}" | wc -l | tr -d ' ')
	if [[ "$count" != "0" ]]; then
		echo "unresolved placeholders found: $count"
		grep -HnE '\[[A-Z0-9_]+\]' "${legal_docs[@]}" || true
	else
		echo "no unresolved placeholders found"
	fi
}

if [[ "$MODE" == "check" ]]; then
	echo "validated required placeholder values from: $ENV_FILE"
	report_unresolved
	exit 0
fi

for doc in "${legal_docs[@]}"; do
	perl -i -pe '
		BEGIN {
			%r = (
				"[SUPPORT_EMAIL]" => $ENV{"SUPPORT_EMAIL"},
				"[PRIVACY_EMAIL]" => $ENV{"PRIVACY_EMAIL"},
				"[DPO_EMAIL_OR_CONTACT]" => $ENV{"DPO_EMAIL_OR_CONTACT"},
				"[POSTAL_ADDRESS]" => $ENV{"POSTAL_ADDRESS"},
				"[APP_STORE_URL_OR_WEBSITE]" => $ENV{"APP_STORE_URL_OR_WEBSITE"},
				"[ANALYTICS_PROVIDER]" => $ENV{"ANALYTICS_PROVIDER"},
				"[ANALYTICS_PRIVACY_URL]" => $ENV{"ANALYTICS_PRIVACY_URL"},
			);
		}
		for $k (keys %r) {
			s/\Q$k\E/$r{$k}/g;
		}
	' "$doc"
done

echo "placeholder replacement applied using: $ENV_FILE"
report_unresolved
