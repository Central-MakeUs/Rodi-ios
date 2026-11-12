#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_root"

ruby <<'RUBY'
require "uri"

paths = `rg --files --hidden -g '*.md' -g '!**/.git/**'`.lines.map(&:strip)
missing = []

paths.each do |path|
  File.read(path).scan(/\[[^\]\n]+\]\(([^\)\n]+)\)/).flatten.each do |raw_target|
    target = raw_target.sub(/\s+".*"$/, "").delete_prefix("<").delete_suffix(">")
    next if target.match?(/\A(?:[a-z][a-z\d+.-]*:|#)/i)

    target = URI::DEFAULT_PARSER.unescape(target.split("#", 2).first.to_s)
    next if target.empty? || target.include?("${") || target.include?("<")

    resolved = File.expand_path(target, File.dirname(path))
    missing << "#{path} -> #{raw_target}" unless File.exist?(resolved)
  end
end

unless missing.empty?
  warn "Missing local Markdown links:"
  missing.each { |item| warn item }
  exit 1
end

puts "Markdown links OK (#{paths.count} files)"
RUBY

if rg -n \
  '/Users/mac/Documents/iOS_projects/SwiftUI/Rodi|테스트 target이 없|Do not copy existing direct `UIScreen.main` usage from `LoginView`|문서 링크·경로와 오래된 안내 문구는 정적 검사 대기 상태|문서·Handoff 정비 진행 중|Docs/Guides/WORKING_GUIDE\.md|Docs/Guides/CODE_DOCUMENTATION_GUIDE\.md|Docs/TODO/(QA_ISSUES|UNRESOLVED_ITEMS)\.md|Docs/Refactoring/PRESENTATION_REFACTORING\.md|Docs/Portfolio/(FEATURE_EXPLORATION_BACKLOG|TECH_BLOG_BACKLOG)\.md|Docs/API/API_CONNECTION_STATUS\.md|Docs/Architecture/Layers/' \
  AGENTS.md Docs Handoff .agents/skills \
  -g '*.md' -g '!Docs/Archive/**' -g '!Handoff/archive/**'
then
  echo "Stale active documentation found" >&2
  exit 1
fi

if rg -n \
  '(^|[[:space:]`(])(\.\./)*(Docs/)?(CodeReview/(BOOTH_VISITOR_FAQ|DEVELOPER_EVALUATION_QA)\.md|Portfolio/AI_UTILIZATION_LOG\.md|Guides/GPS_REPLAY_TESTING\.md)' \
  AGENTS.md Docs Handoff .agents/skills \
  -g '*.md' -g '!Docs/Archive/**' -g '!Handoff/archive/**'
then
  echo "Retired active document path found" >&2
  exit 1
fi

echo "Active documentation checks OK"
