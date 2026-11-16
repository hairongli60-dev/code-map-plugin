#!/usr/bin/env bash
# PreToolUse(Write) 守卫：拦住把代码文件写进临时目录的行为。
# 退出 0 = 放行；退出 2 = 阻止，stderr 会回给 Claude 作为纠正提示。
set -uo pipefail

payload=$(cat)

field() {
  printf '%s' "$payload" \
    | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
    | head -1 \
    | sed 's/.*"\([^"]*\)"$/\1/'
}

norm() { printf '%s' "$1" | tr '\\' '/' | tr -s '/' | tr 'A-Z' 'a-z'; }

raw_path=$(field file_path)
raw_cwd=$(field cwd)
[ -n "$raw_path" ] || exit 0

path=$(norm "$raw_path")
root=$(norm "${raw_cwd:-$PWD}")

# 项目目录内一律放行
case "$path" in
  "$root"/*) exit 0 ;;
esac

# 只守代码文件，文档/数据/图片不管
printf '%s' "$path" | grep -Eq \
  '\.(py|m|r|jl|js|mjs|cjs|ts|tsx|jsx|sh|ps1|c|cpp|h|hpp|go|rs|java|sql|ipynb)$' || exit 0

case "$path" in
  */temp/*|*/tmp/*|*/appdata/local/temp/*|*/windows/temp/*)
    cat >&2 <<EOF
⛔ 临时目录不是代码的家，这个文件没有放行：
   $raw_path

请改写到项目目录下，例如：
   ${raw_cwd:-$PWD}/scripts/

文件名要能说明用途（run_erp_pipeline.py，不是 tmp_analysis.py），
这样它才能被 git 跟踪、被 CODE_MAP.md 收录，下次你才找得到。
EOF
    exit 2
    ;;
esac

exit 0
