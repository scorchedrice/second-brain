#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0

error() {
  printf 'ERROR: %s\n' "$*" >&2
  FAILURES=$((FAILURES + 1))
}

frontmatter_value() {
  local file="$1"
  local key="$2"
  sed -n '2,/^---$/p' "$file" | awk -v key="$key" '
    index($0, key ":") == 1 {
      sub("^[^:]+:[[:space:]]*", "", $0)
      gsub(/^"|"$/, "", $0)
      print
      exit
    }
  '
}

frontmatter_list_items() {
  local file="$1"
  local key="$2"
  sed -n '2,/^---$/p' "$file" | awk -v key="$key" '
    $0 == key ":" { in_list = 1; next }
    in_list && /^[^[:space:]]/ { exit }
    in_list && /^[[:space:]]*-[[:space:]]*/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      gsub(/^"|"$/, "", $0)
      print
    }
  '
}

require_field() {
  local file="$1"
  local key="$2"
  if ! sed -n '2,/^---$/p' "$file" | grep -Eq "^${key}:"; then
    error "${file#$ROOT/}: missing field '$key'"
  fi
}

required_paths=(
  raw/sources/papers
  raw/sources/web
  raw/sources/youtube
  raw/sources/courses
  raw/notes
  raw/assets
  wiki/sources/papers
  wiki/sources/web
  wiki/sources/youtube
  wiki/sources/courses
  wiki/concepts
  wiki/thoughts
  wiki/questions
  wiki/index.md
  wiki/log.md
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$ROOT/$path" ]]; then
    error "missing required path: $path"
  fi
done

if [[ -d "$ROOT/wiki" ]]; then
  while IFS= read -r file; do
    rel="${file#$ROOT/}"
    first_line="$(sed -n '1p' "$file")"
    if [[ "$first_line" != '---' ]]; then
      error "$rel: missing opening YAML delimiter"
      continue
    fi

    for field in type status created updated aliases tags sources related; do
      require_field "$file" "$field"
    done

    actual_type="$(frontmatter_value "$file" type)"
    actual_status="$(frontmatter_value "$file" status)"
    expected_type=''

    case "$rel" in
      wiki/sources/*) expected_type='source' ;;
      wiki/concepts/*) expected_type='concept' ;;
      wiki/thoughts/*) expected_type='thought' ;;
      wiki/questions/*) expected_type='question' ;;
    esac

    if [[ -n "$expected_type" && "$actual_type" != "$expected_type" ]]; then
      error "$rel: type '$actual_type' does not match folder '$expected_type'"
    fi

    case "$actual_type" in
      source)
        require_field "$file" source_type
        require_field "$file" ingestion_status
        source_type="$(frontmatter_value "$file" source_type)"
        expected_source_type=''
        case "$rel" in
          wiki/sources/papers/*) expected_source_type='paper' ;;
          wiki/sources/web/*) expected_source_type='web' ;;
          wiki/sources/youtube/*) expected_source_type='youtube' ;;
          wiki/sources/courses/*) expected_source_type='course' ;;
        esac
        if [[ -n "$expected_source_type" && "$source_type" != "$expected_source_type" ]]; then
          error "$rel: source_type '$source_type' does not match folder '$expected_source_type'"
        fi
        if [[ "$source_type" == 'course' ]]; then
          require_field "$file" formats
          require_field "$file" raw_sources

          format_count=0
          format_pptx=0
          format_pdf=0
          while IFS= read -r format; do
            [[ -z "$format" ]] && continue
            format_count=$((format_count + 1))
            case "$format" in
              pptx) format_pptx=1 ;;
              pdf) format_pdf=1 ;;
              *) error "$rel: unsupported course format '$format'" ;;
            esac
          done < <(frontmatter_list_items "$file" formats)

          raw_count=0
          raw_pptx=0
          raw_pdf=0
          while IFS= read -r raw_link; do
            [[ -z "$raw_link" ]] && continue
            raw_count=$((raw_count + 1))
            target="${raw_link#\[\[}"
            target="${target%\]\]}"
            target="${target%%|*}"
            case "$target" in
              raw/sources/courses/*.pptx) raw_pptx=1 ;;
              raw/sources/courses/*.pdf) raw_pdf=1 ;;
              *) error "$rel: invalid course raw source '$target'" ;;
            esac
          done < <(frontmatter_list_items "$file" raw_sources)

          if [[ "$format_count" -eq 0 ]]; then
            error "$rel: formats must contain at least one item"
          fi
          if [[ "$raw_count" -eq 0 ]]; then
            error "$rel: raw_sources must contain at least one item"
          fi
          if [[ "$format_pptx" -ne "$raw_pptx" || "$format_pdf" -ne "$raw_pdf" ]]; then
            error "$rel: course formats do not match raw_sources extensions"
          fi
        else
          require_field "$file" raw_source
        fi
        case "$actual_status" in
          unread|learning|understood|integrated|revisit) ;;
          *) error "$rel: invalid source status '$actual_status'" ;;
        esac
        ingestion_status="$(frontmatter_value "$file" ingestion_status)"
        case "$ingestion_status" in
          complete|partial) ;;
          *) error "$rel: invalid ingestion_status '$ingestion_status'" ;;
        esac
        ;;
      concept)
        case "$actual_status" in
          draft|integrated|revisit|deprecated) ;;
          *) error "$rel: invalid concept status '$actual_status'" ;;
        esac
        ;;
      thought)
        require_field "$file" kind
        case "$actual_status" in
          proposed|testing|supported|weakened|refuted|superseded) ;;
          *) error "$rel: invalid thought status '$actual_status'" ;;
        esac
        ;;
      question)
        case "$actual_status" in
          open|answered|misframed|superseded) ;;
          *) error "$rel: invalid question status '$actual_status'" ;;
        esac
        ;;
    esac

    index_target="${rel%.md}"
    if [[ -f "$ROOT/wiki/index.md" ]] && \
       ! grep -Fq "[[$index_target" "$ROOT/wiki/index.md"; then
      error "$rel: not registered in wiki/index.md"
    fi
  done < <(find "$ROOT/wiki/sources" "$ROOT/wiki/concepts" \
    "$ROOT/wiki/thoughts" "$ROOT/wiki/questions" -type f -name '*.md' 2>/dev/null | sort)

  while IFS= read -r file; do
    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      target="${link#\[\[}"
      target="${target%\]\]}"
      target="${target%%|*}"
      target="${target%%#*}"
      [[ -z "$target" ]] && continue
      if [[ ! -e "$ROOT/$target" && ! -e "$ROOT/$target.md" ]]; then
        error "${file#$ROOT/}: broken wikilink '[[$target]]'"
      fi
    done < <(grep -Eo '\[\[[^]]+\]\]' "$file" || true)
  done < <(find "$ROOT/wiki" -type f -name '*.md' | sort)
fi

if [[ "$FAILURES" -gt 0 ]]; then
  printf 'wiki lint: FAIL (%d error(s))\n' "$FAILURES" >&2
  exit 1
fi

printf 'wiki lint: PASS\n'
