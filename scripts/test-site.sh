#!/usr/bin/env bash
# 빌드된 _site 를 검사한다. 의존성은 bash/grep/find, 7·13·14번 검사만 node 18.17+
# (ubuntu-latest 러너에 기본 설치돼 있다).
#   사용: scripts/test-site.sh [_site 경로]
#
# 검사 항목은 전부 "실제로 깨진 적이 있는 것"이다. Jekyll 빌드는 이런 것들이
# 틀려도 성공하기 때문에 빌드 성공만으로는 아무것도 보장되지 않는다.
set -uo pipefail

SITE="${1:-_site}"
SITE_URL="https://snutiise.github.io"
FAIL=0

ok()   { printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m %s\n     → %s\n' "$1" "$2"; FAIL=1; }
head_() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[[ -d "$SITE" ]] || { echo "FATAL: $SITE 없음 — jekyll build 를 먼저 실행"; exit 1; }

HOME_HTML="$SITE/index.html"
# 목록 페이지(/posts/, /tags/ …)가 아니라 실제 글을 고른다. 전에는
# itemprop="datePublished" 로 골랐는데 series.html·tags.html 에도 있어서
# /series/ 가 '포스트'로 검사되고 있었다(grep 순회 순서에 따라 대상도 바뀌었다).
# <div class="time"> 은 _layouts/post.html 에만 있다. sort 로 대상을 고정한다.
POST_HTML="$(grep -rl '<div class="time">' "$SITE" --include=index.html 2>/dev/null | grep -v '/feed-research/' | sort | head -1)"

head_ "1. 절대 URL 메타데이터"
# site.url 이 비면 상대경로로 렌더돼 링크 미리보기·정규 URL·RSS가 전부 깨진다.
for tag in 'og:url' 'og:image'; do
  v=$(grep -o "property=\"$tag\" content=\"[^\"]*\"" "$HOME_HTML" | head -1 | sed 's/.*content="//;s/"$//')
  if [[ "$v" == https://* ]]; then ok "$tag 절대경로 ($v)"; else bad "$tag 가 절대 URL이 아님" "실제값: '$v'"; fi
done
CANON=$(grep -o 'rel="canonical" href="[^"]*"' "$HOME_HTML" | head -1 | sed 's/.*href="//;s/"$//')
[[ "$CANON" == https://* ]] && ok "canonical 절대경로" || bad "canonical 이 절대 URL이 아님" "실제값: '$CANON'"

head_ "2. URL 중복 (baseurl 오설정 회귀 방지)"
# url 과 baseurl 을 둘 다 도메인으로 채우면 https://x.iohttps://x.io/ 가 나온다.
DUP=$(grep -roh 'https://snutiise\.github\.iohttps\?://' "$SITE" --include='*.html' --include='*.xml' | head -1)
[[ -z "$DUP" ]] && ok "도메인 중복 없음" || bad "URL이 두 번 붙었다" "발견: $DUP"

head_ "3. og:image 실물 존재"
# 홈만 보던 시절 /series/ 의 og:image(series.png, 없는 파일)가 깨진 채 통과했다.
# 페이지마다 front matter image: 로 바뀌므로 og:image 가 있는 모든 페이지를 본다.
OGMISS=""; OGN=0
while IFS= read -r f; do
  grep -q 'property="og:image"' "$f" || continue
  IMG=$(grep -o 'property="og:image" content="[^"]*"' "$f" | head -1 | sed 's/.*content="//;s/"$//')
  OGN=$((OGN+1))
  [[ "$IMG" == "$SITE_URL"* && -f "$SITE${IMG#$SITE_URL}" ]] || OGMISS+="${f#$SITE} → '$IMG'  "
done < <(find "$SITE" -name '*.html' -not -path '*/feed-research/*' | sort)
[[ -z "$OGMISS" ]] && ok "og:image 파일 존재 (${OGN}개 페이지)" || bad "og:image 가 존재하지 않는 파일을 가리킴" "$OGMISS"

head_ "4. 포스트 og:image 폴백"
# 포스트 front matter 의 image: '' 는 Liquid에서 truthy라 빈 값이 새어나간 적이 있다.
if [[ -n "$POST_HTML" ]]; then
  PV=$(grep -o 'property="og:image" content="[^"]*"' "$POST_HTML" | head -1 | sed 's/.*content="//;s/"$//')
  [[ "$PV" == https://*.* ]] && ok "포스트 og:image 채워짐" || bad "포스트 og:image 가 비었거나 경로 없음" "실제값: '$PV' ($POST_HTML)"
else bad "포스트 페이지를 찾지 못함" "빌드 산출물 구조 확인 필요"; fi

head_ "5. meta description"
# front matter 의 description: '' 가 Liquid 에서 truthy 라 전 페이지 description 이
# 비어 나간 적이 있다. 비어 있으면 검색결과 스니펫·링크 미리보기가 망가진다.
for f in "$HOME_HTML" "$POST_HTML"; do
  [[ -n "$f" && -f "$f" ]] || continue
  D=$(grep -o 'name="description" content="[^"]*"' "$f" | head -1 | sed 's/.*content="//;s/"$//')
  W=$(echo "$D" | wc -c | tr -d ' ')
  # 사이트 설명("snutiise git blog")이 17자라 임계는 그보다 낮게 둔다 — 목적은 "비어 있음" 검출이다.
  if (( W > 12 )); then ok "description 채워짐 (${W}바이트, ${f#$SITE})"
  else bad "description 이 비었거나 너무 짧다" "'${D}' (${f#$SITE})"; fi
done

head_ "6. RSS / 사이트맵"
FEED="$SITE/feed.xml"
if [[ -f "$FEED" ]]; then
  L=$(grep -o '<link>[^<]*</link>' "$FEED" | head -1 | sed 's/<[^>]*>//g')
  [[ "$L" == https://* ]] && ok "RSS link 절대경로" || bad "RSS link 가 상대경로 — 피드 리더에서 글을 못 연다" "실제값: '$L'"
  grep -q '<atom:link href="https://' "$FEED" && ok "atom:link 절대경로" || bad "atom:link 가 상대경로" "self 링크는 절대 URL이어야 한다"
else bad "feed.xml 이 빌드되지 않음" "$FEED"; fi
SM="$SITE/sitemap.xml"
if [[ -f "$SM" ]]; then
  # grep -c 는 줄 수를 센다. 사이트맵은 <loc> 여러 개가 한 줄에 나오므로
  # 실제 96개를 26개로, feed-research 71개를 1개로 세고 있었다. grep -o 로 센다.
  N=$(grep -o '<loc>' "$SM" | wc -l | tr -d ' '); P=$(find "$SITE" -name index.html -path '*/*/*' | wc -l | tr -d ' ')
  (( N > 0 )) && ok "사이트맵 URL ${N}개" || bad "사이트맵이 비었다" "포스트 ${P}개"
  grep -q '<loc>https://' "$SM" && ok "사이트맵 절대경로" || bad "사이트맵이 상대경로" "검색엔진이 색인 못 함"
  # 하드코딩한 루트 <url> 과 html_pages 루프가 같은 URL 을 두 번 낸 적이 있다.
  SMDUP=$(grep -o '<loc>[^<]*</loc>' "$SM" | sort | uniq -d | sed 's/<[^>]*>//g' | tr '\n' ' ')
  [[ -z "$SMDUP" ]] && ok "사이트맵 URL 중복 없음" || bad "사이트맵에 같은 URL 이 두 번 있다" "$SMDUP"
  # feed-research 리포트는 front matter 가 없어 site.pages 가 아니라
  # site.static_files 루프로만 사이트맵에 들어간다. 그 루프가 깨지면 사이트에서
  # 가장 자주 갱신되는 페이지 70여 개가 통째로 색인 밖으로 사라진다.
  # "1개 이상"으로는 70개가 빠져도 통과하므로 실제 파일 수와 맞춘다.
  R=$(grep -o '<loc>[^<]*/feed-research/' "$SM" | wc -l | tr -d ' ')
  FR=$(find "$SITE/feed-research" -name '*.html' 2>/dev/null | wc -l | tr -d ' ')
  (( R > 0 && R >= FR )) && ok "사이트맵에 feed-research ${R}개 포함 (리포트 ${FR}개)" || bad "사이트맵에 feed-research 리포트가 빠졌다" "사이트맵 ${R}개 / 리포트 ${FR}개 — sitemap.xml 의 site.static_files 루프 확인"
else bad "sitemap.xml 이 빌드되지 않음" "$SM"; fi

head_ "7. Liquid 누수"
# 렌더되지 않은 {{ }} / {% %} 가 남아 있으면 템플릿 오류다. 코드 블록은 뺀다 — 글이
# AngularJS·Jinja 같은 예제를 {% raw %} 로 감싸 일부러 {{ }} 를 내보내는 자리이고
# (electron3), 전에는 그걸 Liquid 가 먹어 예제가 빈 값으로 나가고 있었다.
if LEAK=$(node - "$SITE" <<'JS'
const fs = require('fs'), path = require('path');
const site = process.argv[2], out = [];
for (const rel of fs.readdirSync(site, { recursive: true }).sort()) {
  if (!/\.(html|xml)$/.test(rel) || rel.split(path.sep).includes('feed-research')) continue;
  const text = fs.readFileSync(path.join(site, rel), 'utf8')
    .replace(/<pre\b[\s\S]*?<\/pre>/gi, '').replace(/<code\b[\s\S]*?<\/code>/gi, '');
  if (/\{\{|\{%/.test(text)) out.push(rel);
}
console.log(out.slice(0, 3).join(' '));
JS
); then
  [[ -z "$LEAK" ]] && ok "미렌더 Liquid 없음 (코드 블록 제외)" || bad "렌더되지 않은 Liquid 구문" "$LEAK"
else bad "node 로 Liquid 누수를 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

head_ "8. 404 페이지"
[[ -f "$SITE/404.html" ]] && ok "404.html 존재" || bad "404.html 없음" "GitHub 기본 404가 노출된다"

head_ "9. 죽은 서비스 참조"
for dead in 'plus.google.com' 'lovelyzfan.xyz'; do
  # 템플릿은 모든 페이지에 렌더되므로 홈 하나만 보면 충분하다.
  H=$(grep -l "$dead" "$HOME_HTML" 2>/dev/null | head -1)
  [[ -z "$H" ]] && ok "$dead 참조 없음" || bad "죽은 서비스 참조가 남아 있다" "$dead → $H"
done

head_ "10. 내부 링크/이미지 무결성"
# 페이지 목록을 head 로 자르지 않는다. 전에는 head -40 이라 40개를 넘는 페이지를 조용히 건너뛰었다.
MISS=0
while IFS= read -r f; do
  while IFS= read -r ref; do
    [[ -z "$ref" || "$ref" == "#"* || "$ref" == "//"* ]] && continue
    # http(s) 포함 모든 URI 스킴(mailto:, spotify:, data: …)은 내부 참조가 아니다
    [[ "$ref" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*: ]] && continue
    t="${ref%%#*}"; t="${t%%\?*}"; [[ -z "$t" ]] && continue
    [[ "$t" == /* ]] && p="$SITE$t" || p="$(dirname "$f")/$t"
    [[ -e "$p" || -e "${p%/}/index.html" ]] || { echo "     누락: $t (in ${f#$SITE})"; MISS=$((MISS+1)); }
  done < <(grep -oE '(href|src)="[^"]*"' "$f" | sed 's/.*="//;s/"$//')
done < <(find "$SITE" -name '*.html' -not -path '*/feed-research/*')
(( MISS == 0 )) && ok "내부 참조 전부 해결됨" || bad "깨진 내부 참조 ${MISS}건" "위 목록 참조"

head_ "11. /posts/ 목록 제목 원문"
# tree-posts.html 의 replace: ' ','_' 때문에 목록 제목이 '데이터_중심_…' 으로 나갔다.
# 피드의 글 제목(첫 <title> 은 사이트 제목이라 뺀다) 중 공백이 있는 것의 밑줄판이
# 목록에 있으면 실패다. 원문 일치로 보지 않는 이유: 피드는 XML 이스케이프를 거쳐
# '&' 같은 글자가 든 제목은 원문 비교가 오탐한다.
LIST="$SITE/posts/index.html"; MANGLED=""
while IFS= read -r t; do
  [[ "$t" == *" "* ]] && grep -qF ">${t// /_}<" "$LIST" 2>/dev/null && MANGLED+="'${t// /_}' "
done < <(grep -o '<title>[^<]*</title>' "$FEED" 2>/dev/null | sed '1d;s/<[^>]*>//g')
if [[ ! -f "$LIST" ]]; then bad "/posts/index.html 이 빌드되지 않음" "$LIST"
elif [[ -z "$MANGLED" ]]; then ok "목록 제목에 공백→밑줄 치환 없음"
else bad "목록 제목의 공백이 밑줄로 바뀌었다" "$MANGLED(_includes/tree-posts.html)"; fi

head_ "12. 페이지 배경색"
# main.css 는 html/body 에 배경을 주지 않는다. 캔버스가 어두운 환경에서는 #333 본문이
# 투명 배경 위에 놓여 거의 안 보였다. main.css 는 다시 빌드하면 안 되므로 배경은
# custom.css 에서 준다. 규칙이 여러 줄에 걸쳐도 잡히게 개행을 펴서 본다.
CSS="$SITE/assets/css/custom.css"
if tr '\n' ' ' < "$CSS" 2>/dev/null | grep -Eq '(^|[},[:space:]])(html|body)[[:space:]]*(,[^{]*)?\{[^}]*background'; then ok "custom.css 에 html/body 배경 지정"
else bad "html/body 배경이 없다" "$CSS 에 html 또는 body 의 background 규칙이 없다"; fi

head_ "13. 인라인 스크립트"
# 두 번 깨진 적이 있다. (1) _layouts/compress.html 은 <pre> 밖의 개행을 전부 지워서
# 인라인 <script> 가 한 줄이 되고, 첫 // 주석이 그 뒤 코드를 모두 삼킨다(네이버
# 분석 설정이 이렇게 사라졌다). (2) Liquid 값을 이스케이프 없이 JS 문자열에 넣어
# 따옴표 하나로 SyntaxError 가 나고 댓글이 뜨지 않았다. 둘 다 빌드와 html-proofer 를
# 통과하고 브라우저 콘솔에서만 보인다. node 로 파싱만 하고 실행하지는 않는다.
# // 판별은 휴리스틱이다: 개행이 없는 스크립트 본문에서 앞이 줄머리·공백·; { } 이고
# 뒤가 공백인 // 를 주석으로 본다('//' + x 나 https:// 는 걸리지 않는다).
if JS_BAD=$(node - "$SITE" <<'JS'
const fs = require('fs'), path = require('path'), vm = require('vm');
const site = process.argv[2], out = [];
for (const rel of fs.readdirSync(site, { recursive: true }).sort()) {
  if (!rel.endsWith('.html') || rel.split(path.sep).includes('feed-research')) continue;
  const html = fs.readFileSync(path.join(site, rel), 'utf8');
  for (const [, attrs, body] of html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)) {
    if (/\bsrc=/i.test(attrs) || (/\btype=/i.test(attrs) && !/javascript/i.test(attrs))) continue;
    try { new vm.Script(body); } catch (e) { out.push(`${rel}: ${e.message}`); continue; }
    if (!body.includes('\n') && /(^|[;{}\s])\/\/\s/.test(body)) out.push(`${rel}: 한 줄로 뭉개진 스크립트에 // 주석`);
  }
}
console.log(out.join('\n'));
JS
); then
  [[ -z "$JS_BAD" ]] && ok "인라인 스크립트 파싱 통과, 뭉개진 // 주석 없음" || bad "인라인 스크립트가 깨졌다" "${JS_BAD//$'\n'/ / }"
else bad "node 로 인라인 스크립트를 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

head_ "14. 포스트 코드 예제"
# 두 번 깨진 적이 있다. (1) 이미지 지연 로딩을 일괄 치환하다 코드 예제 안의 문자열
# <img …> 에도 loading/decoding 속성을 끼워 넣었다(electron2, dcmacro). (2) electron3 의
# AngularJS 예제 {{todo.done}} 등을 Liquid 가 먹어 빈 값으로 나갔다. 둘 다 빌드는 통과한다.
# 코드 블록의 태그를 벗기고 엔티티를 풀어 원문 그대로 본다.
if CODE_BAD=$(node - "$SITE" <<'JS'
const fs = require('fs'), path = require('path');
const site = process.argv[2], out = [];
const unescape = (s) => s.replace(/<[^>]+>/g, '').replace(/&quot;/g, '"').replace(/&#39;/g, "'")
  .replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&amp;/g, '&');
for (const rel of fs.readdirSync(site, { recursive: true }).sort()) {
  if (!rel.endsWith('index.html') || rel.split(path.sep).includes('feed-research')) continue;
  const html = fs.readFileSync(path.join(site, rel), 'utf8');
  for (const [, pre] of html.matchAll(/<pre\b[^>]*>([\s\S]*?)<\/pre>/gi)) {
    if (/loading="lazy"|decoding="async"/.test(unescape(pre))) { out.push(`${rel}: 코드 예제에 loading/decoding 속성이 끼어들었다`); break; }
  }
}
const e3 = path.join(site, 'electron3', 'index.html');
if (fs.existsSync(e3) && !unescape(fs.readFileSync(e3, 'utf8')).includes('{{todo.text}}'))
  out.push('electron3/index.html: AngularJS 예제의 {{todo.text}} 가 사라졌다 — {% raw %} 확인');
console.log(out.join('\n'));
JS
); then
  [[ -z "$CODE_BAD" ]] && ok "코드 예제 원문 보존" || bad "포스트 코드 예제가 깨졌다" "${CODE_BAD//$'\n'/ / }"
else bad "node 로 코드 예제를 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

echo
if (( FAIL )); then printf '\033[31m실패 — 위 FAIL 항목을 고칠 것\033[0m\n'; exit 1; fi
printf '\033[32m전체 통과\033[0m\n'
