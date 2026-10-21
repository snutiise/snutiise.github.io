#!/usr/bin/env bash
# 빌드된 _site 를 검사한다. 의존성은 bash/grep/find, 7·13·14·15·16·17·18번 검사만 node 18.17+
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
# og:type article 은 head.html 이 layout 'post' 에만 낸다. sort 로 대상을 고정한다.
# 영어 글(en/)은 한국어 글과 따로 고른다 — 한국어 글만 POST_HTML 이다.
POST_HTML="$(grep -rl 'property="og:type" content="article"' "$SITE" --include=index.html 2>/dev/null | grep -v '/feed-research/' | grep -v "^${SITE%/}/en/" | sort | head -1)"
EN_HOME="$SITE/en/index.html"
EN_POST_HTML="$(grep -rl 'property="og:type" content="article"' "$SITE/en" --include=index.html 2>/dev/null | sort | head -1)"

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
SITE_DESC=$(grep -o 'name="description" content="[^"]*"' "$HOME_HTML" | head -1 | sed 's/.*content="//;s/"$//')
for f in "$HOME_HTML" "$POST_HTML" "$EN_HOME" "$EN_POST_HTML"; do
  [[ -n "$f" && -f "$f" ]] || continue
  D=$(grep -o 'name="description" content="[^"]*"' "$f" | head -1 | sed 's/.*content="//;s/"$//')
  W=$(echo "$D" | wc -c | tr -d ' ')
  # 사이트 설명("snutiise git blog")이 17자라 임계는 그보다 낮게 둔다 — 목적은 "비어 있음" 검출이다.
  if (( W > 12 )); then ok "description 채워짐 (${W}바이트, ${f#$SITE})"
  else bad "description 이 비었거나 너무 짧다" "'${D}' (${f#$SITE})"; fi
done
# 포스트는 본문 앞부분이 설명이어야 한다. page.layout == 'post' 판별이 깨지면 포스트도
# 사이트 설명으로 떨어지고 og:type·JSON-LD 가 함께 사라지는데 위 검사는 그래도 통과한다.
if [[ -n "$POST_HTML" ]]; then
  PD=$(grep -o 'name="description" content="[^"]*"' "$POST_HTML" | head -1 | sed 's/.*content="//;s/"$//')
  [[ -n "$PD" && "$PD" != "$SITE_DESC" ]] && ok "포스트 description 이 사이트 설명과 다름" || bad "포스트 description 이 사이트 설명으로 떨어졌다" "'$PD' (${POST_HTML#$SITE})"
  grep -q '<script type="application/ld+json">{"@context":"https://schema.org","@type":"BlogPosting"' "$POST_HTML" \
    && ok "포스트 JSON-LD BlogPosting 있음" || bad "포스트에 JSON-LD BlogPosting 이 없다" "${POST_HTML#$SITE}"
  NA=$(grep -rL 'property="og:type" content="article"' $(grep -rl 'id="disqus_thread"' "$SITE" --include=index.html | grep -v '/feed-research/') 2>/dev/null)
  [[ -z "$NA" ]] && ok "댓글이 있는 모든 글이 og:type article" || bad "og:type 이 article 이 아닌 글" "$NA"
fi

head_ "6. RSS / 사이트맵"
# 피드는 언어별로 둘이다(/feed.xml, /en/feed.xml). FEED 는 11번이 쓴다.
FEED="$SITE/feed.xml"
for FD in "$FEED" "$SITE/en/feed.xml"; do
  if [[ -f "$FD" ]]; then
    L=$(grep -o '<link>[^<]*</link>' "$FD" | head -1 | sed 's/<[^>]*>//g')
    [[ "$L" == https://* ]] && ok "RSS link 절대경로 (${FD#$SITE/})" || bad "RSS link 가 상대경로 — 피드 리더에서 글을 못 연다 (${FD#$SITE/})" "실제값: '$L'"
    grep -q '<atom:link href="https://' "$FD" && ok "atom:link 절대경로 (${FD#$SITE/})" || bad "atom:link 가 상대경로 (${FD#$SITE/})" "self 링크는 절대 URL이어야 한다"
  else bad "${FD#$SITE/} 가 빌드되지 않음" "$FD"; fi
done
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
# 예전 main.css 는 html/body 에 배경을 주지 않아, 캔버스가 어두운 환경에서는 #333 본문이
# 투명 배경 위에 놓여 거의 안 보였다. site.css 는 body 에 background: var(--bg) 를 준다.
# 규칙이 여러 줄에 걸쳐도 잡히게 개행을 펴서 본다.
CSS="$SITE/assets/css/site.css"
if tr '\n' ' ' < "$CSS" 2>/dev/null | grep -Eq '(^|[},[:space:]])(html|body)[[:space:]]*(,[^{]*)?\{[^}]*background'; then ok "site.css 에 html/body 배경 지정"
else bad "html/body 배경이 없다" "$CSS 에 html 또는 body 의 background 규칙이 없다"; fi

head_ "13. 인라인 스크립트·이벤트 속성 (CSP 에 'unsafe-inline' 이 없다)"
# head.html 의 CSP 는 'unsafe-inline' 없이 script-src 'self' + 정해진 서드파티 파일만 허용한다.
# 동작은 전부 /assets/js/site.js 에 있다. 템플릿에 인라인 <script>·onclick 같은 속성·javascript:
# 링크가 다시 들어오면 브라우저가 막아 기능이 조용히 죽는다(빌드와 html-proofer 는 통과한다).
# 예전에는 실제로 인라인 스크립트가 두 번 깨졌다(compress 레이아웃의 // 주석, 따옴표 미이스케이프).
# - src 없는 <script> 는 type 이 application/ld+json·application/json 인 데이터 블록만 허용
# - 데이터 블록은 JSON.parse 가 돼야 하고 '</' 가 없어야 한다(jsonify 는 </script> 를 이스케이프하지 않는다)
# - 실제 태그(<로 시작, 본문 코드 예제의 &lt; 는 해당 없음)에 on*= 속성, href/src 의 javascript: 금지
# feed-research/ 도 같은 규칙으로 본다. 생성기(build-html.mjs)의 자체 검사가 1차이고, 여기가 게시본에 대한 2차다.
if JS_BAD=$(node - "$SITE" <<'JS'
const fs = require('fs'), path = require('path');
const site = process.argv[2], out = [];
let pages = 0, blocks = 0;
for (const rel of fs.readdirSync(site, { recursive: true }).sort()) {
  if (!rel.endsWith('.html')) continue;
  pages++;
  const html = fs.readFileSync(path.join(site, rel), 'utf8');
  for (const [, attrs, body] of html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi)) {
    if (/\bsrc\s*=/i.test(attrs)) {
      if (body.trim()) out.push(`${rel}: src 가 있는 <script> 에 본문이 있다`);
      continue;
    }
    const type = (attrs.match(/\btype\s*=\s*[\x22\x27]?([^\x22\x27\s>]+)/i) || [])[1] || '';
    if (!/^application\/(ld\+)?json$/i.test(type)) { out.push(`${rel}: 인라인 <script${attrs}>`); continue; }
    blocks++;
    if (body.includes('</')) out.push(`${rel}: JSON 데이터 블록 안에 '</'`);
    try { JSON.parse(body); } catch (e) { out.push(`${rel}: JSON 데이터 블록 파싱 실패 (${e.message})`); }
  }
  const tags = html.replace(/<!--[\s\S]*?-->/g, '').match(/<[a-zA-Z][^>]*>/g) || [];
  for (const t of tags) {
    const ev = t.match(/\son[a-z]+\s*=/i);
    if (ev) out.push(`${rel}: 이벤트 속성 ${ev[0].trim()} in ${t.slice(0, 80)}`);
    if (/\s(href|src|action|formaction)\s*=\s*[\x22\x27]?\s*javascript:/i.test(t)) out.push(`${rel}: javascript: URL in ${t.slice(0, 80)}`);
  }
}
if (!pages) out.push('검사한 HTML 이 없다');
console.log(out.join('\n'));
console.error(`  (${pages}개 페이지, JSON 데이터 블록 ${blocks}개)`);
JS
); then
  [[ -z "$JS_BAD" ]] && ok "인라인 스크립트·이벤트 속성·javascript: URL 없음, JSON 데이터 블록 정상" || bad "CSP 가 막을 인라인 코드가 있다" "${JS_BAD//$'\n'/ / }"
else bad "node 로 인라인 스크립트를 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

# jsonify 는 </script> 를 이스케이프하지 않는다. 지금 글 제목에는 < 가 없어 위 산출물 검사로는
# 이스케이프가 빠져도 통과하므로 템플릿을 직접 본다: JSON-LD 의 jsonify 마다 replace: '<', '\u003c' 가 붙어야 한다.
HEAD_T="$(dirname "$0")/../_includes/head.html"
LD=$(grep 'application/ld+json' "$HEAD_T" 2>/dev/null)
NJ=$(grep -o 'jsonify' <<<"$LD" | wc -l | tr -d ' ')
NE=$(grep -oF "jsonify | replace: '<', '\u003c'" <<<"$LD" | wc -l | tr -d ' ')
(( NJ > 0 && NJ == NE )) && ok "JSON-LD 의 jsonify ${NJ}곳 모두 '<' 이스케이프" || bad "JSON-LD 값에 '<' 이스케이프가 빠졌다" "jsonify ${NJ}곳 중 ${NE}곳만 replace: '<', '\u003c' ($HEAD_T)"

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
for (const e of ['electron3', 'en/electron3']) {   // 영어판의 {% raw %} 누락도 같은 회귀다
  const e3 = path.join(site, e, 'index.html');
  if (fs.existsSync(e3) && !unescape(fs.readFileSync(e3, 'utf8')).includes('{{todo.text}}'))
    out.push(`${e}/index.html: AngularJS 예제의 {{todo.text}} 가 사라졌다 — {% raw %} 확인`);
}
console.log(out.join('\n'));
JS
); then
  [[ -z "$CODE_BAD" ]] && ok "코드 예제 원문 보존" || bad "포스트 코드 예제가 깨졌다" "${CODE_BAD//$'\n'/ / }"
else bad "node 로 코드 예제를 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

head_ "15. 공통 머리·꼬리 바이트 일치 (언어별)"
# 머리글(건너뛰기 링크~</header>)·바닥글은 언어마다 블로그와 feed-research 생성기가 같은 바이트를 낸다(생성기 build-html.mjs 의
# HEADER_KO/EN·FOOTER_KO/EN). 페이지마다 다른 것은 언어 전환 링크(<a class="lang-switch">)의 href 하나 — 짝 페이지(없으면 다른
# 언어의 섹션 홈)라서다. 그 값만 비우고 비교하고, 값이 맞는지는 17번이 본다. 현재 메뉴 표시는 body[data-nav] 를 CSS 가 읽으므로
# 그 밖에 달라질 것이 없다. 리서치 쪽은 목록·일일·정본이 서로 다른 생성 경로라 하나씩 넣는다. 영어 리서치의 일일·정본은
# 번역 백로그 때문에 아직 없을 수 있어 있으면 넣는다(생성기 자체 검사가 1차로 전부 본다).
if HF_BAD=$(node - "$SITE" "$POST_HTML" "$EN_POST_HTML" <<'JS'
const fs = require('fs'), path = require('path');
const [site, post, enPost] = process.argv.slice(2), out = [];
const ls = (d) => { const p = path.join(site, d); return fs.existsSync(p) ? fs.readdirSync(p).filter((f) => f.endsWith('.html')).sort() : []; };
const daily = (d) => { const f = ls(d).filter((f) => /^daily-\d{4}-\d{2}-\d{2}\.html$/.test(f)).at(-1); return f ? `${d}/${f}` : ''; };
const canon = (d) => { const f = ls(d).filter((f) => !/^(index|daily)/.test(f))[0]; return f ? `${d}/${f}` : ''; };
const rel = (p) => (p ? path.relative(site, p) : '');
const sets = {
  ko: ['index.html', 'posts/index.html', rel(post), 'about/index.html', '404.html',
       'feed-research/index.html', 'feed-research/x.html', 'feed-research/daily.html', daily('feed-research')],
  en: ['en/index.html', 'en/posts/index.html', rel(enPost), 'en/about/index.html',
       'feed-research/en/index.html',
       ...['feed-research/en/daily.html', daily('feed-research/en'), canon('feed-research/en')]
          .filter((f) => f && fs.existsSync(path.join(site, f)))],
};
const grab = (h, re) => (h.match(re) || [])[0];
const norm = (s) => s.replace(/<a class=\x22lang-switch\x22 href=\x22[^\x22]*\x22/, '<a class="lang-switch" href=""');
let n = 0;
for (const [lang, files] of Object.entries(sets)) {
  const seen = { head: new Map(), foot: new Map() };
  for (const f of files) {
    const p = path.join(site, f);
    if (!f || !fs.existsSync(p)) { out.push(`${f || `(${lang} 글)`}: 파일 없음`); continue; }
    n++;
    const h = fs.readFileSync(p, 'utf8');
    if (!h.includes(`<html lang="${lang}">`)) out.push(`${f}: <html lang="${lang}"> 가 아니다`);
    const head = grab(h, /<a class="skip" href="#content">[\s\S]*?<\/header>/), foot = grab(h, /<footer class="site-foot">[\s\S]*?<\/footer>/);
    if (!head) out.push(`${f}: 공통 헤더 없음`);
    else {
      if ((head.match(/<a class="lang-switch"/g) || []).length !== 1) out.push(`${f}: 언어 전환 링크가 하나가 아니다`);
      seen.head.set(norm(head), [...(seen.head.get(norm(head)) || []), f]);
    }
    if (!foot) out.push(`${f}: 공통 푸터 없음`); else seen.foot.set(foot, [...(seen.foot.get(foot) || []), f]);
  }
  for (const k of ['head', 'foot']) if (seen[k].size > 1) out.push(`${lang} ${k} 가 ${seen[k].size}가지: ` + [...seen[k].values()].map((v) => v.join(',')).join(' | '));
}
console.log(out.join('\n'));
console.error(`  (${n}개 페이지, 언어별 비교)`);
JS
); then
  [[ -z "$HF_BAD" ]] && ok "헤더·푸터가 언어마다 모든 비교 페이지에서 같은 바이트 (전환 링크 href 제외)" || bad "헤더·푸터가 페이지마다 다르다" "${HF_BAD//$'\n'/ / }"
else bad "node 로 헤더·푸터를 비교하지 못함" "node 가 설치돼 있는지 확인"; fi

head_ "16. CSS 가 부르는 파일 (웹폰트)"
# site.css 는 첫 규칙인 @import 로 자체 호스팅 Pretendard(assets/fonts/pretendard/)를 부른다. 리서치 페이지도
# 같은 site.css 를 쓰고 CSP 가 font-src 'self' 라, 다른 출처 URL 은 브라우저가 막는다. @import 앞에 규칙이 하나라도
# 있으면 브라우저가 @import 를 버린다. 페이지 CSP 에 font-src 'self' 가 없어도 막힌다(아래). 넷 다 빌드·html-proofer 는
# 통과하고 글꼴만 조용히 시스템 글꼴로 떨어진다.
if CSS_BAD=$(node - "$SITE" <<'JS'
const fs = require('fs'), path = require('path');
const site = process.argv[2], out = [];
let refs = 0, fonts = 0, pages = 0;
const strip = (t) => t.replace(/\/\*[\s\S]*?\*\//g, '');
const main = path.join(site, 'assets/css/site.css');
if (!/^\s*@import\s/.test(strip(fs.readFileSync(main, 'utf8')))) out.push('site.css: 첫 규칙이 @import 가 아니다');
const seen = new Set(), todo = [main];
while (todo.length) {
  const f = todo.pop();
  if (seen.has(f)) continue;
  seen.add(f);
  if (!fs.existsSync(f)) { out.push(`${path.relative(site, f)}: 파일 없음`); continue; }
  for (const [, , u] of strip(fs.readFileSync(f, 'utf8')).matchAll(/url\x28\s*([\x22\x27]?)([^\x22\x27\x29]+)\1\s*\x29/g)) {
    if (u.startsWith('data:')) continue;
    const v = u.replace(/[?#].*/, '');
    refs++;
    if (/^[a-z][a-z0-9+.-]*:|^\/\//i.test(u)) { out.push(`${path.relative(site, f)}: 다른 출처 ${u}`); continue; }
    const p = v.startsWith('/') ? path.join(site, v) : path.join(path.dirname(f), v);
    if (p.endsWith('.css')) todo.push(p); else if (!fs.existsSync(p)) out.push(`${path.relative(site, f)}: 없는 파일 ${u}`);
    if (/\.(woff2?|ttf|otf)$/i.test(v)) fonts++;
  }
}
// 글꼴을 부르면 site.css 를 쓰는 모든 페이지의 CSP 가 글꼴을 허용해야 한다. feed-research/ 의 CSP 는 다른 저장소의
// 생성기가 낸다(default-src none). 그쪽 font-src self 판이 게시되기 전에 글꼴이 들어오면 리서치 페이지마다
// woff2 92개가 CSP 에 막혀 콘솔 오류가 난다(화면은 시스템 글꼴이라 빌드·html-proofer·눈으로는 안 보인다).
// 머지 순서(feed-research 먼저)를 사람이 기억하지 않아도 여기서 빨간불이 된다.
const blocked = [];
const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) {
  const p = path.join(d, e.name);
  if (e.isDirectory()) { walk(p); continue; }
  if (!e.name.endsWith('.html')) continue;
  const h = fs.readFileSync(p, 'utf8'), m = h.match(/http-equiv=\x22Content-Security-Policy\x22 content=\x22([^\x22]*)\x22/);
  if (!fonts || !m || !h.includes('/assets/css/site.css')) continue;
  pages++;
  const dir = Object.fromEntries(m[1].split(';').map((s) => s.trim().split(/\s+/)).filter((a) => a[0]).map(([k, ...v]) => [k.toLowerCase(), v]));
  const pol = dir['font-src'] || dir['default-src'];
  if (pol && !pol.includes('\x27self\x27') && !pol.includes('*')) blocked.push(path.relative(site, p));
} };
walk(site);
if (blocked.length) out.push(`CSP 가 글꼴을 막는 페이지 ${blocked.length}개 (예: ${blocked[0]}) — font-src \x27self\x27 가 없다. feed-research/ 면 생성기의 font-src \x27self\x27 판을 먼저 게시할 것`);
console.log(out.slice(0, 5).join('\n'));
console.error(`  (CSS ${seen.size}개, url() ${refs}개, 글꼴 ${fonts}개, CSP 검사 페이지 ${pages}개)`);
JS
); then
  [[ -z "$CSS_BAD" ]] && ok "CSS 의 @import·url() 이 전부 같은 출처이고 산출물에 있으며, 모든 페이지의 CSP 가 그 글꼴을 허용한다" || bad "CSS 가 부르는 파일이 깨졌다" "${CSS_BAD//$'\n'/ / }"
else bad "node 로 CSS 참조를 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

head_ "17. 언어와 짝 (html lang, hreflang 왕복, 전환 링크, 댓글 스레드)"
# 영어판 URL = 블로그 '/en' + 한국어판 URL, 리서치 '/feed-research/en/' + 같은 파일 이름(아래 isEn·twinOf·homeOf 가 그 정의다.
# feed-research 생성기와 같은 함수). 짝이 있으면 head 에 hreflang ko·en·x-default(=ko) 세 줄이 있고, 짝도 같은 세 줄로 되돌아오며,
# 머리글의 전환 링크가 짝을 가리킨다. 짝이 없으면 hreflang 이 없고 전환 링크는 다른 언어의 섹션 홈이다.
# 짝 파일이 있는데 선언하지 않은 페이지(생성기·템플릿이 짝을 못 찾은 것)도 실패다. 리서치 페이지도 같은 규칙.
# 영어 페이지 안에서 영어판이 있는 한국어 페이지로 가는 링크는 번역 누락이다(언어를 넘는 링크는 hreflang 을 단다).
# 영어 내용 페이지의 Disqus data-url 은 한국어 원문 주소여야 한다(스레드 공유).
if I18N_BAD=$(node - "$SITE" <<'JS'
const fs = require('fs'), path = require('path');
const site = process.argv[2], ORIGIN = 'https://snutiise.github.io', out = [];
const isEn   = (f) => f.startsWith('en/') || f.startsWith('feed-research/en/');
const isFr   = (f) => f.startsWith('feed-research/');
const twinOf = (f) => isEn(f) ? f.replace(/^(feed-research\/)?en\//, '$1')
                    : isFr(f) ? 'feed-research/en/' + f.slice('feed-research/'.length)
                    : 'en/' + f;
const homeOf = (f) => isFr(f) ? (isEn(f) ? '/feed-research/' : '/feed-research/en/')
                    : (isEn(f) ? '/' : '/en/');
const pages = new Map();
for (const f of fs.readdirSync(site, { recursive: true }).sort()) {
  if (!f.endsWith('.html')) continue;
  const h = fs.readFileSync(path.join(site, f), 'utf8');
  if (/<html\b/i.test(h)) pages.set(f.split(path.sep).join('/'), h);   // google*/naver* 확인 파일은 <html 이 없다
}
const fileOf = (u) => { const p = decodeURIComponent(u).replace(/^\//, ''); return p === '' || p.endsWith('/') ? p + 'index.html' : p; };
const urlOf = (f) => '/' + f.replace(/(^|\/)index\.html$/, '$1');
const altsOf = (h) => Object.fromEntries([...h.matchAll(/<link rel=\x22alternate\x22 hreflang=\x22([^\x22]+)\x22 href=\x22([^\x22]+)\x22>/g)].map((m) => [m[1], m[2]]));
const article = (h) => h.includes('property="og:type" content="article"');
let pairs = 0;
const koOnly = { post: [], research: [] };
for (const [f, h] of pages) {
  const en = isEn(f), lang = en ? 'en' : 'ko', other = en ? 'ko' : 'en', twin = twinOf(f);
  const hl = (h.match(/<html lang=\x22([^\x22]*)\x22/) || [])[1];
  if (hl !== lang) { out.push(`${f}: <html lang="${hl}"> — ${lang} 여야 한다`); continue; }
  const sw = h.match(/<a class=\x22lang-switch\x22 href=\x22([^\x22]*)\x22 hreflang=\x22([^\x22]*)\x22 lang=\x22([^\x22]*)\x22/);
  if (!sw) { out.push(`${f}: 언어 전환 링크 없음`); continue; }
  if (sw[2] !== other || sw[3] !== other) out.push(`${f}: 전환 링크의 hreflang·lang 이 ${other} 가 아니다`);
  const a = altsOf(h), keys = Object.keys(a).sort().join();
  if (!keys) {
    const home = homeOf(f);
    if (sw[1] !== home) out.push(`${f}: 짝이 없으면 전환 링크는 ${home} 다 (${sw[1]})`);
    if (pages.has(twin)) out.push(`${f}: 짝 ${twin} 이 있는데 hreflang 이 없다`);
    // 리서치 고아(한국어 원문을 지우거나 개명한 뒤 남은 영어판)는 en-sync.py status 가 보고하고 사람이 지운다 — 막지 않는다. 블로그 고아는 18번도 본다.
    if (en && !isFr(f) && article(h)) out.push(`${f}: 영어판에 한국어 원문이 없다 — 파일 이름이 원문과 같아야 한다`);
    else if (!en && article(h)) koOnly[isFr(f) ? 'research' : 'post'].push(f);
    continue;
  }
  if (keys !== 'en,ko,x-default') { out.push(`${f}: hreflang 이 ko·en·x-default 셋이 아니다 (${keys})`); continue; }
  pairs++;
  if (a[lang] !== ORIGIN + urlOf(f)) out.push(`${f}: hreflang="${lang}" 이 자기 주소가 아니다 (${a[lang]})`);
  if (a['x-default'] !== a.ko) out.push(`${f}: x-default 가 한국어판이 아니다`);
  if (en) {   // 댓글 스레드는 한국어 원문과 같이 쓴다. data-url 은 escape 필터를 거쳐 작은따옴표가 &#39; 로 나온다
    const du = (h.match(/<div id=\x22disqus_thread\x22 data-url=\x22([^\x22]*)\x22/) || [])[1];
    if (du) { const d = du.replace(/&#39;/g, "'").replace(/&amp;/g, '&');
      if (d !== a.ko) out.push(`${f}: 영어판 댓글 스레드가 한국어 원문 주소가 아니다 (${d})`); }
  }
  if (!a[other].startsWith(ORIGIN + '/')) { out.push(`${f}: hreflang="${other}" 가 이 사이트가 아니다`); continue; }
  const op = a[other].slice(ORIGIN.length);
  if (sw[1] !== op) out.push(`${f}: 전환 링크 ${sw[1]} ≠ hreflang="${other}" ${op}`);
  if (fileOf(op) !== twin) out.push(`${f}: 짝은 ${twin} 이어야 하는데 ${fileOf(op)}`);
  const t = pages.get(fileOf(op));
  if (!t) { out.push(`${f}: 짝 ${op} 이 산출물에 없다`); continue; }
  const back = altsOf(t);
  if (back.ko !== a.ko || back.en !== a.en) out.push(`${f}: ${op} 의 hreflang 이 되돌아오지 않는다`);
}
for (const [f, h] of pages) {
  if (!isEn(f)) continue;
  for (const [tag] of h.matchAll(/<a\b[^>]*>/g)) {
    if (/\shreflang=\x22/.test(tag)) continue;
    const u = (tag.match(/\shref=\x22(\/[^\x22#?]*)/) || [])[1];
    if (!u || isEn(u.slice(1)) || u.startsWith('/assets/')) continue;
    if (pages.has(twinOf(fileOf(u)))) out.push(`${f}: 한국어 ${u} 로 링크한다 — 영어판 ${twinOf(fileOf(u))} 이 있다`);
  }
}
console.log(out.slice(0, 20).join('\n'));
console.error(`  (짝 ${pairs / 2}쌍, 영어판이 없는 한국어 글 ${koOnly.post.length}개·리서치 ${koOnly.research.length}개)`);
JS
); then
  [[ -z "$I18N_BAD" ]] && ok "html lang·hreflang 왕복·전환 링크·댓글 스레드·영어 페이지 내부 링크 정상" || bad "언어·짝이 어긋났다" "${I18N_BAD//$'\n'/ / }"
else bad "node 로 언어·짝을 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

head_ "18. 영어 글 번역 짝 (_posts ↔ _en_posts)"
# 산출물이 아니라 원본을 본다(13번 템플릿 검사처럼 $(dirname "$0")/..). 파일 이름이 짝을 정한다(같은 slug). 한국어 글마다 영어판이
# 있어야 하고, front matter 키는 layout·title·date·categories·tags·ko_sha 뿐이며 날짜·시리즈·태그는 원문과 같다. 원문이 바뀌면
# ko_sha(원문 파일의 git blob sha1, `git hash-object _posts/<파일>` 과 같다)가 어긋나 실패한다 — 영어판을 맞춘 뒤 메시지의 값으로 고친다.
# 코드 블록은 번역하지 않는다: 블록 수·줄 수가 같고, 한글이 없는 줄은 바이트까지 같아야 한다(한글 주석이 있는 줄만 옮길 수 있다).
# 외부 URL·/assets 경로 집합, {% raw %} 수, 제목(#) 수, HTML 태그 이름 목록, Liquid 구문 수, 본문 줄 수도 원문과 같아야 한다.
# 코드 밖에 한글이 남으면 실패(URL 과 <span lang="ko"> 안은 허용).
if TR_BAD=$(node - "$(dirname "$0")/.." <<'JS'
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const root = process.argv[2], out = [];
const KO = path.join(root, '_posts'), EN = path.join(root, '_en_posts');
const md = (d) => (fs.existsSync(d) ? fs.readdirSync(d).filter((f) => f.endsWith('.md')).sort() : []);
const ko = md(KO), en = md(EN);
const HANGUL = /[ᄀ-ᇿ㄰-㆏가-힣]/;
const parse = (s) => {               // _posts 가 쓰는 꼴만: `key: value` 와 `- item` 목록
  const m = s.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!m) return null;
  const fm = {}; let k = null;
  for (const line of m[1].split('\n')) {
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/), it = line.match(/^- (.*)$/);
    if (kv) { k = kv[1]; fm[k] = kv[2] === '' ? [] : kv[2].replace(/^([\x22\x27])(.*)\1$/, '$2'); }
    else if (it && Array.isArray(fm[k])) fm[k].push(it[1]);
  }
  return { fm, body: m[2] };
};
const CODE = /\{% highlight [^%]*%\}([\s\S]*?)\{% endhighlight %\}|^\x60{3}[^\n]*\n([\s\S]*?)^\x60{3}/gm;
const blocks = (b) => [...b.matchAll(CODE)].map((m) => (m[1] ?? m[2]).split('\n'));
// 끝의 문장부호는 URL 이 아니다: 'https://github.com/ 실행 결과' 가 영어에서 'https://github.com/.' 가 된다.
const set = (b, re) => [...new Set([...b.matchAll(re)].map((m) => m[1].replace(/[.,;:!?]+$/, '')))].sort().join(' ');
const count = (b, re) => (b.match(re) || []).length;
// 영어판이 한국어로 남기는 말은 <span lang="ko"> 로 감싼다(허용). 그 span 만 태그 목록에서 뺀다.
const tags = (b) => [...b.replace(CODE, '').replace(/<span lang=\x22ko\x22>/g, '').matchAll(/<([a-zA-Z][\w-]*)/g)].map((m) => m[1].toLowerCase()).sort().join();
const liq = (b) => (b.replace(CODE, '').match(/\{\{|\{%/g) || []).length;
const ALLOWED = new Set(['layout', 'title', 'date', 'categories', 'tags', 'ko_sha']);
for (const f of ko) if (!en.includes(f)) out.push(`_en_posts/${f} 없음 — 한국어 글마다 같은 파일 이름의 영어판을 둔다`);
for (const f of en) {
  if (!ko.includes(f)) { out.push(`_en_posts/${f}: 같은 이름의 _posts 원문이 없다`); continue; }
  const raw = fs.readFileSync(path.join(KO, f)), K = parse(raw.toString('utf8')), E = parse(fs.readFileSync(path.join(EN, f), 'utf8'));
  if (!K || !E) { out.push(`${f}: front matter 를 읽지 못함`); continue; }
  const want = crypto.createHash('sha1').update(Buffer.concat([Buffer.from(`blob ${raw.length}\0`), raw])).digest('hex');
  if (E.fm.ko_sha !== want) out.push(`_en_posts/${f}: 원문이 바뀌었다 — 영어판을 맞춘 뒤 ko_sha: ${want}`);
  for (const k of Object.keys(E.fm)) if (!ALLOWED.has(k)) out.push(`_en_posts/${f}: front matter 키 ${k} 는 쓰지 않는다 (허용: ${[...ALLOWED].join(',')})`);
  for (const k of ['date', 'categories', 'tags']) if (JSON.stringify(E.fm[k]) !== JSON.stringify(K.fm[k])) out.push(`_en_posts/${f}: ${k} 가 원문과 다르다`);
  if (E.fm.layout !== 'post') out.push(`_en_posts/${f}: layout: post 가 없다`);
  if (!E.fm.title || HANGUL.test(E.fm.title)) out.push(`_en_posts/${f}: 제목이 비었거나 한글이 남았다`);
  const kc = blocks(K.body), ec = blocks(E.body);
  if (kc.length !== ec.length) out.push(`_en_posts/${f}: 코드 블록 ${ec.length}개 / 원문 ${kc.length}개`);
  else kc.forEach((lines, i) => {
    if (lines.length !== ec[i].length) { out.push(`_en_posts/${f}: 코드 블록 ${i + 1} 줄 수가 다르다`); return; }
    lines.forEach((l, j) => { if (!HANGUL.test(l) && l !== ec[i][j]) out.push(`_en_posts/${f}: 코드 블록 ${i + 1} 의 ${j + 1}행이 바뀌었다`); });
  });
  const URL = /(https?:\/\/[^\s\x22\x27<>\x29\]\u3130-\u318f\uac00-\ud7a3]+)/g, ASSET = /(\/assets\/[^\s\x22\x27<>\x29]+)/g;
  if (set(K.body, URL) !== set(E.body, URL)) out.push(`_en_posts/${f}: 외부 URL 집합이 원문과 다르다`);
  if (set(K.body, ASSET) !== set(E.body, ASSET)) out.push(`_en_posts/${f}: /assets 경로 집합이 원문과 다르다`);
  if (count(K.body, /\{%-?\s*(end)?raw\s*-?%\}/g) !== count(E.body, /\{%-?\s*(end)?raw\s*-?%\}/g)) out.push(`_en_posts/${f}: {% raw %} 수가 다르다`);
  const heads = (b) => count(b.replace(CODE, ''), /^#{1,6} /gm);
  if (heads(K.body) !== heads(E.body)) out.push(`_en_posts/${f}: 제목(#) 수가 다르다`);
  if (tags(K.body) !== tags(E.body)) out.push(`_en_posts/${f}: HTML 태그가 원문과 다르다`);
  if (liq(K.body) !== liq(E.body)) out.push(`_en_posts/${f}: Liquid 태그 수가 원문과 다르다`);
  if (K.body.split('\n').length !== E.body.split('\n').length) out.push(`_en_posts/${f}: 본문 줄 수가 원문과 다르다`);
  const prose = E.body.replace(CODE, '').replace(/https?:\/\/[^\s\x22\x27<>\x29\]]+/g, '').replace(/\x60[^\x60\n]*\x60/g, '').replace(/<span lang=\x22ko\x22>[^<]*<\/span>/g, '');
  const left = prose.match(new RegExp(`.{0,20}${HANGUL.source}.{0,20}`));
  if (left) out.push(`_en_posts/${f}: 코드 밖에 한글이 남았다 — "${left[0]}"`);
}
console.log(out.slice(0, 20).join('\n'));
console.error(`  (한국어 ${ko.length}편 / 영어 ${en.length}편)`);
JS
); then
  [[ -z "$TR_BAD" ]] && ok "모든 글에 영어판이 있고 원문과 짝이 맞는다" || bad "영어 글 번역 짝이 어긋났다" "${TR_BAD//$'\n'/ / }"
else bad "node 로 번역 짝을 검사하지 못함" "node 가 설치돼 있는지 확인"; fi

echo
if (( FAIL )); then printf '\033[31m실패 — 위 FAIL 항목을 고칠 것\033[0m\n'; exit 1; fi
printf '\033[32m전체 통과\033[0m\n'
