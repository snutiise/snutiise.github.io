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
- **`feed-research/` 와 `_data/feed_research.yml` 을 손으로 고치지 않는다.**
  feed-research 저장소의 `scripts/publish-html.sh` 가 매일 생성해 이 저장소에
  커밋·푸시한다. 여기서 고치면 다음 게시 때 덮인다. 고칠 것은 그 저장소에서 고친다.

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| `_posts/` | 글 (Markdown) |
| `_layouts/`, `_includes/` | 템플릿. 테마 gem 없이 전부 여기 있는 것만 쓴다(`base`, `post` 두 레이아웃) |
| `assets/css/site.css` | 사이트 전체 스타일(블로그 + feed-research). 웹폰트·외부 CSS 없음 |
| `assets/js/site.js` | 메뉴 표시, 목차 따라가기, /posts/ 거르기, Disqus 클릭 로드(글·리서치), Naver 분석(운영 주소의 블로그 페이지에서만) |
| `assets/img/` | 글 이미지, 파비콘 |
| `feed-research/`, `_data/feed_research.yml` | 생성물. 위 "하지 말 것" 참고 |
| `scripts/test-site.sh` | 빌드 산출물 검사 |
| `google*.html`, `naver*.html` | 검색엔진 소유 확인 파일. 지우지 않는다 |
