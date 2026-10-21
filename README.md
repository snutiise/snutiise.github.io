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
  리서치 내용 페이지에도 글과 같은 댓글 버튼이 있다. 그 페이지들의 CSP(생성기의 `withCsp`)는
  Disqus 에 `embed.js` 와 `disqus.com/embed/comments/` iframe 만 열어 두므로, site.js 의 Disqus
  코드가 다른 것을 불러오게 바꾸면 리서치 쪽에서는 막힌다.
- **외부 글꼴·외부 CSS 를 부르지 않는다.** 블로그 CSP 는 `font-src 'self'`, 리서치 페이지 CSP 는
  `default-src 'none'` 에 `font-src 'self'`·`style-src 'self'` 만 연다. 글꼴은 아래 "글꼴" 의 자체 호스팅
  파일만 쓴다. `scripts/test-site.sh` 16번 검사가 CSS 의 `@import`·`url()` 이 같은 출처이고 산출물에
  있는지, `@import` 가 `site.css` 의 첫 규칙인지 본다(앞에 규칙이 있으면 브라우저가 `@import` 를 버린다).
- **`feed-research/` 와 `_data/feed_research.yml` 을 손으로 고치지 않는다.**
  feed-research 저장소의 `scripts/publish-html.sh` 가 매일 생성해 이 저장소에
  커밋·푸시한다. 여기서 고치면 다음 게시 때 덮인다. 고칠 것은 그 저장소에서 고친다.

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| `_posts/` | 글 (Markdown) |
| `_layouts/`, `_includes/` | 템플릿. 테마 gem 없이 전부 여기 있는 것만 쓴다(`base`, `post` 두 레이아웃) |
| `assets/css/site.css` | 사이트 전체 스타일(블로그 + feed-research). 첫 규칙에서 `assets/fonts/pretendard/pretendard.css` 를 `@import` 한다. 외부 CSS 없음 |
| `assets/fonts/pretendard/` | 자체 호스팅 웹폰트. 아래 "글꼴" 참고 |
| `assets/js/site.js` | 메뉴 표시, 목차 따라가기, /posts/ 거르기, 코드 블록 복사 버튼, Disqus 클릭 로드(글·리서치), Naver 분석(운영 주소의 블로그 페이지에서만) |
| `assets/img/` | 글 이미지, 파비콘 |
| `feed-research/`, `_data/feed_research.yml` | 생성물. 위 "하지 말 것" 참고 |
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
