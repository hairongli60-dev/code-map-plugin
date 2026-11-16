#!/usr/bin/env bash
# code-map 扫描器：输出紧凑的代码清单，供 Claude 生成 CODE_MAP.md。
# 用法：bash scan.sh [项目根目录]
set -uo pipefail

root="${1:-}"
if [ -z "$root" ]; then
  root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi
cd "$root" || exit 1

CODE_EXT='\.(py|m|r|jl|js|mjs|cjs|ts|tsx|jsx|sh|ps1|c|cpp|h|hpp|go|rs|java|sql|ipynb)$'

echo "# ROOT: $PWD"
echo "# BRANCH: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"
echo "# HEAD: $(git log -1 --format='%h %cs %s' 2>/dev/null || echo '-')"
echo

echo "## TRACKED CODE (path | lines | last-commit)"
git ls-files 2>/dev/null | grep -Ei "$CODE_EXT" | while IFS= read -r f; do
  [ -f "$f" ] || continue
  lines=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
  mod=$(git log -1 --format=%cs -- "$f" 2>/dev/null)
  printf '%-72s %5s  %s\n' "$f" "$lines" "${mod:--}"
done
echo

echo "## UNTRACKED / MODIFIED — 这些就是「找不到的新代码」"
git status --porcelain 2>/dev/null \
  | grep -E '^(\?\?| M|M |A )' \
  | sed 's/^...//' \
  | grep -Ei "$CODE_EXT"
echo

echo "## DATA / OUTPUT (可能该进 .gitignore)"
git status --porcelain 2>/dev/null \
  | sed 's/^...//' \
  | grep -Ei '\.(mat|bdf|edf|npy|npz|pkl|h5|hdf5|pt|pth|onnx|csv|parquet|png|pdf|log)$'
echo

echo "## ENTRYPOINTS — 有 __main__ / 顶层 main 的脚本"
grep -rlE --include='*.py' --include='*.sh' \
  -e 'if __name__ ==' -e '^main\(\)' . 2>/dev/null \
  | sed 's|^\./||' | head -50
echo

echo "## DIR SUMMARY (file count)"
git ls-files 2>/dev/null | awk -F/ 'NF>1{print $1"/"} NF==1{print "./"}' \
  | sort | uniq -c | sort -rn | head -20
