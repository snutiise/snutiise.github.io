#!/usr/bin/env bash
# 빌드된 _site 를 검사한다. 의존성은 bash/grep/find 뿐.
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
# 목록 페이지(/posts/, /tags/ …)가 아니라 실제 글을 고른다 — 포스트에만 있는
# datePublished 마크업으로 판별한다.
POST_HTML="$(grep -rl 'itemprop="datePublished"' "$SITE" --include=index.html 2>/dev/null | grep -v '/feed-research/' | head -1)"

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
IMG=$(grep -o 'property="og:image" content="[^"]*"' "$HOME_HTML" | head -1 | sed 's/.*content="//;s/"$//')
IMG_PATH="$SITE${IMG#$SITE_URL}"
if [[ "$IMG" == "$SITE_URL"* && -f "$IMG_PATH" ]]; then ok "og:image 파일 존재 ($(basename "$IMG_PATH"))"
else bad "og:image 가 존재하지 않는 파일을 가리킴" "URL=$IMG / 기대 경로=$IMG_PATH"; fi

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
  N=$(grep -c '<loc>' "$SM"); P=$(find "$SITE" -name index.html -path '*/*/*' | wc -l | tr -d ' ')
  (( N > 0 )) && ok "사이트맵 URL ${N}개" || bad "사이트맵이 비었다" "포스트 ${P}개"
  grep -q '<loc>https://' "$SM" && ok "사이트맵 절대경로" || bad "사이트맵이 상대경로" "검색엔진이 색인 못 함"
else bad "sitemap.xml 이 빌드되지 않음" "$SM"; fi

head_ "7. Liquid 누수"
# 렌더되지 않은 {{ }} / {% %} 가 남아 있으면 템플릿 오류다.
LEAK=$(grep -rl --include='*.html' --include='*.xml' -E '\{\{|\{%' "$SITE" 2>/dev/null | grep -v '/feed-research/' | head -3)
[[ -z "$LEAK" ]] && ok "미렌더 Liquid 없음" || bad "렌더되지 않은 Liquid 구문" "$(echo "$LEAK" | tr '\n' ' ')"

head_ "8. 404 페이지"
[[ -f "$SITE/404.html" ]] && ok "404.html 존재" || bad "404.html 없음" "GitHub 기본 404가 노출된다"

head_ "9. 죽은 서비스 참조"
for dead in 'plus.google.com' 'lovelyzfan.xyz'; do
  # 템플릿은 모든 페이지에 렌더되므로 홈 하나만 보면 충분하다.
  H=$(grep -l "$dead" "$HOME_HTML" 2>/dev/null | head -1)
  [[ -z "$H" ]] && ok "$dead 참조 없음" || bad "죽은 서비스 참조가 남아 있다" "$dead → $H"
done

head_ "10. 내부 링크/이미지 무결성"
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
done < <(find "$SITE" -name '*.html' -not -path '*/feed-research/*' | head -40)
(( MISS == 0 )) && ok "내부 참조 전부 해결됨" || bad "깨진 내부 참조 ${MISS}건" "위 목록 참조"

echo
if (( FAIL )); then printf '\033[31m실패 — 위 FAIL 항목을 고칠 것\033[0m\n'; exit 1; fi
printf '\033[32m전체 통과\033[0m\n'
