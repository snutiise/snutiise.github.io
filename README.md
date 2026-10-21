# 0x00 - NULL

snutiise 의 개인 블로그 소스. <https://snutiise.github.io/>

Jekyll 사이트이고, GitHub Pages 가 `master` 브랜치를 `github-pages` gem 으로
빌드해 배포한다. 별도 빌드 단계나 npm 은 없다. `master` 에 푸시하면 끝이다.

## 미리보기와 검사

로컬에서 띄우기 (CI 와 같은 Ruby 3.3 권장):

```sh
bundle install
bundle exec jekyll serve          # http://127.0.0.1:4000
```

PR·푸시마다 CI(`.github/workflows/ci.yml`)가 아래를 돌린다. 로컬에서도 같다.

```sh
JEKYLL_ENV=production bundle exec jekyll build
scripts/test-site.sh _site
htmlproofer _site --disable-external --ignore-missing-alt --allow-missing-href --no-enforce-https
```

Ruby 를 깔기 어려우면 CI 가 올린 빌드 산출물(`site`, 5일 보관)을 받아 본다.

```sh
gh run download <run-id> -n site -D /tmp/site
python3 -m http.server 4000 --bind 127.0.0.1 -d /tmp/site
```

외부 링크는 `links.yml` 이 매주 따로 점검해 깨지면 이슈를 연다.

## 하지 말 것

- **인라인 `<script>`·`onclick=` 같은 이벤트 속성·`javascript:` 링크를 넣지 않는다.**
  `_includes/head.html` 의 CSP 에 `'unsafe-inline'` 이 없어서 브라우저가 막는다.
  동작은 `assets/js/site.js` 에 더한다(`innerHTML` 대신 `textContent`).
  `scripts/test-site.sh` 13번 검사가 막는다.
- **`assets/css/site.css`·`assets/js/site.js` 는 feed-research 페이지도 쓴다.**
  리서치 생성기가 `/assets/css/site.css` 를 링크하고, 공통 헤더·푸터
  (`_includes/site-header.html`, `_includes/site-footer.html`)와 같은 바이트를 낸다.
  리서치 컴포넌트 규칙을 지우거나 헤더·푸터를 바꿀 때는 그쪽 템플릿도 같이 바꾼다.
  한국어·영어 헤더·푸터가 따로 있고(`page.lang`), 둘 다 생성기의 `HEADER_KO/EN`·`FOOTER_KO/EN` 과 같은 바이트여야 한다
  (페이지마다 다른 것은 `<li class="lang">` 의 href 하나. 15번이 그 값만 비우고 비교한다).
  리서치 내용 페이지에도 글과 같은 댓글 버튼이 있다. 그 페이지들의 CSP(생성기의 `withCsp`)는
  Disqus 에 `embed.js` 와 `disqus.com/embed/comments/` iframe 만 열어 두므로, site.js 의 Disqus
  코드가 다른 것을 불러오게 바꾸면 리서치 쪽에서는 막힌다.
- **외부 글꼴·외부 CSS 를 부르지 않는다.** 블로그 CSP 는 `font-src 'self'`, 리서치 페이지 CSP 는
  `default-src 'none'` 에 `font-src 'self'`·`style-src 'self'` 만 연다. 글꼴은 아래 "글꼴" 의 자체 호스팅
  파일만 쓴다. `scripts/test-site.sh` 16번 검사가 CSS 의 `@import`·`url()` 이 같은 출처이고 산출물에
  있는지, `@import` 가 `site.css` 의 첫 규칙인지 본다(앞에 규칙이 있으면 브라우저가 `@import` 를 버린다).
  `site.css` 를 쓰는 모든 페이지의 CSP 가 글꼴을 허용하는지도 본다. 리서치 페이지의 CSP 는 생성기가 내므로,
  생성기에서 `font-src 'self'` 를 빼면(또는 그 판이 게시되기 전에 글꼴을 들이면) 이 검사가 실패한다.
- **`feed-research/`(한국어 `feed-research/*.html` 과 영어 `feed-research/en/`)와 `_data/feed_research.yml`·
  `_data/feed_research_en.yml` 을 손으로 고치지 않는다.**
  feed-research 저장소의 `scripts/publish-html.sh` 가 매일 생성해 이 저장소에
  커밋·푸시한다. 여기서 고치면 다음 게시 때 덮인다. 고칠 것은 그 저장소에서 고친다.
- **한국어 글을 고치면 같은 PR 에서 영어판도 맞춘다.** `scripts/test-site.sh` 18번이 `_en_posts/` 의 `ko_sha`(원문의
  git blob sha1)와 원문을 대조해서, 원문만 고치면 빨갛게 된다. feed-research 클론에서 다음으로 영어판을 갱신하고
  `ko_sha` 를 메시지의 값으로 고친다(자세한 것은 아래 "영어판").

## 영어판

영어 URL 은 블로그가 `/en/` + 한국어 URL(`/electron1/` ↔ `/en/electron1/`, `/posts/` ↔ `/en/posts/`), 리서치가
`/feed-research/en/` + 같은 파일 이름이다. 머리글 맨 끝의 `EN`/`KO` 가 전환 링크이고, 짝이 있으면 짝으로, 없으면 다른 언어의
섹션 홈(`/en/`·`/`, 리서치는 `/feed-research/en/`·`/feed-research/`)으로 간다.

- **글**: `_en_posts/` 에 `_posts/` 와 **같은 파일 이름**으로 둔다(같은 slug → 같은 규칙으로 짝이 맞는다). front matter 는
  `layout: post`, `title`, `date`, `categories`, `tags`, `ko_sha` 뿐이다(`date`·`categories`·`tags` 는 원문 바이트 그대로).
  본문은 원문과 줄 단위로 대응한다. 컬렉션이라 `site.posts`·`site.tags`·한국어 피드·이전/다음 글에 섞이지 않는다.
- **페이지**: `en/index.html`, `en/posts.html`, `en/series.html`, `en/tags.html`, `en/about.html`, `en/feed.xml`. 한국어 페이지를
  고치면 짝 파일도 고친다. 공용 문자열(날짜·읽는 시간·목차·댓글 …)은 `_data/i18n.yml` 에 있다.
- **언어 판정**: `_config.yml` 의 `defaults` 가 `page.lang`(`ko`/`en`)을 준다. `en/` 아래와 `_en_posts` 는 `en`.
  `<html lang>`, 머리글·바닥글, `hreflang` 세 줄(짝이 있을 때만), `og:locale`, 피드 링크가 이것을 따른다.
- **댓글**: 영어 글은 한국어 원문 스레드를 같이 쓴다(`data-url`·`data-title` = 원문). 영어 글의 메타에는
  `Translated from: Korean` 링크가 있다.
- **영어 글 갱신**: 번역 엔진은 feed-research 저장소의 `scripts/en-sync.py` 다. 한국어 글을 고친 뒤 그쪽 클론에서

  ```sh
  python3 -I scripts/en-sync.py plan … --blog <이 저장소>/_posts <이 저장소>/_en_posts --only <파일 이름>
  ```

  (또는 `FEED_EN_BLOG="<ko> <en>" FEED_EN_ONLY=<파일 이름> scripts/translate-en.sh`)을 돌려 영어판과 `ko_sha` 를 맞춘다.
  원문을 지우거나 이름을 바꾸면 `_en_posts/` 에 고아가 남는다. 사람이 같이 지운다.
- **검사**: `scripts/test-site.sh` 15번(언어별 헤더·푸터 바이트), 17번(`html lang`·`hreflang` 왕복·전환 링크·영어 페이지의 한국어 링크·
  댓글 스레드), 18번(`_posts` ↔ `_en_posts` 짝: 파일 이름, 날짜·시리즈·태그, `ko_sha`, 코드 블록, URL 집합, HTML 태그·Liquid 수,
  줄 수, 코드 밖 한글).
- **CSP·site.js**: 영어판도 CSP 는 그대로다. UI 문자열(복사 버튼, 거르기 개수, 미리보기 안내)은 `site.js` 의 `T` 표가
  `<html lang>` 을 보고 고른다.

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| `_posts/` | 글 (Markdown) |
| `_en_posts/` | 영어판 글. `_posts/` 와 같은 파일 이름. 위 "영어판" 참고 |
| `en/` | 영어 페이지(`index`·`posts`·`series`·`tags`·`about`·`feed.xml`) |
| `_data/i18n.yml` | 공용 템플릿의 언어별 UI 문자열 |
| `_layouts/`, `_includes/` | 템플릿. 테마 gem 없이 전부 여기 있는 것만 쓴다(`base`, `post` 두 레이아웃) |
| `assets/css/site.css` | 사이트 전체 스타일(블로그 + feed-research). 첫 규칙에서 `assets/fonts/pretendard/pretendard.css` 를 `@import` 한다. 외부 CSS 없음 |
| `assets/fonts/pretendard/` | 자체 호스팅 웹폰트. 아래 "글꼴" 참고 |
| `assets/js/site.js` | 메뉴 표시, 목차 따라가기, /posts/ 거르기, 코드 블록 복사 버튼, Disqus 클릭 로드(글·리서치), Naver 분석(운영 주소의 블로그 페이지에서만). UI 문자열은 `<html lang>` 별 |
| `assets/img/` | 글 이미지, 파비콘 |
| `feed-research/`(영어 `feed-research/en/` 포함), `_data/feed_research.yml`, `_data/feed_research_en.yml` | 생성물. 위 "하지 말 것" 참고 |
| `scripts/test-site.sh` | 빌드 산출물 검사 |
| `google*.html`, `naver*.html` | 검색엔진 소유 확인 파일. 지우지 않는다 |

## 글꼴

`assets/fonts/pretendard/` 는 [Pretendard](https://github.com/orioncactus/pretendard) 1.3.9 의
variable dynamic subset 이다. 라이선스는 SIL Open Font License 1.1 이고 전문은 같은 폴더의
`LICENSE.txt` 다(패키지의 `dist/LICENSE.txt` 를 그대로 복사).

- 출처: npm `pretendard@1.3.9` tarball (`npm pack pretendard@1.3.9 --ignore-scripts`, 72,081,687 bytes).
  integrity `sha512-PaQAADyLY5v4kYFwkpSJHbSSYIkiriY/1xXw75TKoZ9UQQqeU+tvP05yTdZAWibiIYoo8ZKtRv8PM7w0IaywSw==`
  (`npm view pretendard@1.3.9 dist.integrity` 와 같다). 압축만 풀었고 패키지 안의 어떤 것도 실행하지 않았다.
- 파일: `dist/web/variable/woff2-dynamic-subset/` 의 woff2 92개와
  `dist/web/variable/pretendardvariable-dynamic-subset.css`(→ `pretendard.css`). CSS 는
  `url(./woff2-dynamic-subset/X.woff2)` 를 `url(/assets/fonts/pretendard/X.woff2)` 로만 바꿨고 나머지 바이트는 원본과 같다.
  family 이름은 `'Pretendard Variable'` 하나, `font-display: swap`, `unicode-range` 는 원본 그대로다.
- 쓰임: `--font-sans` 는 `-apple-system, BlinkMacSystemFont, "Apple SD Gothic Neo"` 를 Pretendard 보다
  앞에 둔다. Apple 기기는 시스템 글꼴로 그리고 woff2 를 받지 않는다. 그 밖의 기기는 페이지에 실제로 나오는
  글자의 subset 만 받는다(`unicode-range`).
- 올릴 때: 같은 방식으로 새 버전 tarball 의 integrity 를 `npm view` 값과 맞춘 뒤 두 경로를 바꾸고, 이 절의
  버전·크기·integrity 를 고친다. `.md` 파일은 넣지 않는다(front matter 가 없어도 Jekyll 이 그대로 서빙한다).
