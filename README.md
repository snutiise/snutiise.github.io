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

- **`assets/css/main.css`·`assets/js/main.js` 를 다시 빌드하지 않는다.** 2018년
  gulp 산출물이다. 지금 `src/styl` 로 다시 빌드하면 normalize.css 버전이 바뀌어
  사이트 전체 기본 스타일이 달라진다. 스타일은 main.css 뒤에 로드되는
  `assets/css/custom.css` 에서 덮어쓰고, 동작은 `assets/js/a11y.js` 처럼 별도
  파일로 더한다. 원래 툴체인(package.json, gulpfile.js)은 커밋 219162f 에 남아 있다.
- **`feed-research/` 와 `_data/feed_research.yml` 을 손으로 고치지 않는다.**
  feed-research 저장소의 `scripts/publish-html.sh` 가 매일 생성해 이 저장소에
  커밋·푸시한다. 여기서 고치면 다음 게시 때 덮인다. 고칠 것은 그 저장소에서 고친다.
- **`_layouts/compress.html` 을 거치는 페이지의 인라인 `<script>` 에 `//` 줄 주석을
  쓰지 않는다.** 이 레이아웃은 `<pre>` 밖의 공백(개행 포함)을 전부 뭉개서, `//`
  뒤의 코드가 모두 주석이 된다. `/* */` 를 쓰거나 외부 `.js` 파일로 뺀다.

## 디렉터리

| 경로 | 내용 |
| --- | --- |
| `_posts/` | 글 (Markdown) |
| `_layouts/`, `_includes/` | 템플릿. 테마 gem 없이 전부 여기 있는 것만 쓴다 |
| `assets/css/` | `main.css`(동결), `custom.css`(실제로 고치는 곳) |
| `assets/js/` | `main.js`(동결, Zepto + 검색), `a11y.js`(키보드·포커스 보완) |
| `assets/img/` | 글 이미지, 파비콘 |
| `feed-research/`, `_data/feed_research.yml` | 생성물. 위 "하지 말 것" 참고 |
| `src/` | main.css·main.js 의 2018년 원본(stylus, js). 참고용이고 빌드·배포하지 않는다 |
| `sample/` | 테마가 딸려 보낸 데모 글. 빌드에서 제외된다 |
| `scripts/test-site.sh` | 빌드 산출물 검사 |
| `google*.html`, `naver*.html` | 검색엔진 소유 확인 파일. 지우지 않는다 |
