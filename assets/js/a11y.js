// 메뉴(#slide)·검색(#search)은 href 없는 <a role="button"> 이라 Enter 로 활성화되지
// 않고(WCAG 2.1.1), main.js 는 click 만 걸어 둔다. 그래서 검색은 키보드로 아예 열 수
// 없었고, Space 를 치면 문서 전역 핸들러가 대신 메뉴를 열었다.
//
// 이 코드가 인라인이 아니라 별도 파일인 이유가 있다. _layouts/compress.html 은
// <pre> 밖의 모든 공백을 `split:" " | join:" "` 로 뭉개는데, Ruby 의 String#split(" ")
// 은 개행까지 흡수한다. 인라인으로 두면 이 파일을 거치는 모든 페이지에서 스크립트가
// 한 줄이 되어 첫 // 주석이 나머지 전부를 삼킨다. 실제로 그렇게 넣었다가 홈과 목록
// 페이지에서 통째로 죽어 있었다.
(function () {
  var slide = document.getElementById('slide');
  var fade = document.getElementById('fade');
  [slide, document.getElementById('search')].forEach(function (el) {
    if (!el) return;
    el.addEventListener('keydown', function (e) {
      if (e.key !== 'Enter' && e.key !== ' ') return;
      e.preventDefault();
      // 전역 Space 핸들러가 끼어들어 검색 대신 메뉴를 여는 것을 막는다.
      e.stopPropagation();
      el.click();
    });
  });
  // 메뉴 열림 상태를 스크린리더에 알린다. 여는 곳은 #slide, 닫는 곳은 #fade 뿐이다
  // (Escape 도 main.js 가 #fade 의 click 으로 흘려보낸다).
  if (slide && fade) {
    slide.addEventListener('click', function () { slide.setAttribute('aria-expanded', 'true'); });
    fade.addEventListener('click', function () { slide.setAttribute('aria-expanded', 'false'); });
  }
})();
