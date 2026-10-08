#!/usr/bin/env bash

set -uo pipefail

PREFIXES='Added|Updated|Fixed|Removed|Refactored'
MAX_SUBJECT=72
MAX_LINE=72
status=0

fail() {
  echo "::error::$1"
  status=1
}

check_subject() {
  local subject=$1 label=$2
  if [[ ! $subject =~ ^($PREFIXES)\ [^[:space:]] ]]; then
    fail "$label: subject must start with one of ${PREFIXES//|/, } followed by a description: '$subject'"
  fi
  if ((${#subject} > MAX_SUBJECT)); then
    fail "$label: subject is ${#subject} characters, the limit is $MAX_SUBJECT: '$subject'"
  fi
  if [[ $subject == *. ]]; then
    fail "$label: subject must not end with a period: '$subject'"
  fi
  if [[ $subject =~ (^|[^[:alnum:]])#[0-9]+ ]]; then
    fail "$label: keep issue references out of the subject, use a trailer such as 'Issue: #123': '$subject'"
  fi
}

check_message() {
  local sha=$1 label subject second body line
  label="commit ${sha:0:7}"
  subject=$(git log -1 --format=%s "$sha")
  check_subject "$subject" "$label"

  second=$(git log -1 --format=%B "$sha" | sed -n '2p')
  if [[ -n $second ]]; then
    fail "$label: leave a blank line between the subject and the body"
  fi

  body=$(git log -1 --format=%b "$sha")
  if [[ -z ${body//[[:space:]]/} ]]; then
    fail "$label: add a body explaining why the change was needed"
  fi

  while IFS= read -r line; do
    [[ ${#line} -le MAX_LINE ]] && continue
    [[ $line =~ https?:// || $line =~ ^[[:space:]] ]] && continue
    fail "$label: body line exceeds $MAX_LINE characters: '${line:0:40}...'"
  done <<<"$body"
}

case ${1:-} in
  title)
    check_subject "${2:-}" "PR title"
    ;;
  body)
    if [[ -z ${2//[[:space:]]/} ]]; then
      fail "PR description is empty: explain why the change was needed (squash merges use it as the commit body)"
    fi
    ;;
  range)
    while IFS= read -r sha; do
      check_message "$sha"
    done < <(git rev-list --no-merges "$2..$3")
    ;;
  *)
    echo "usage: $0 title <subject> | body <text> | range <base> <head>" >&2
    exit 2
    ;;
esac

exit $status
