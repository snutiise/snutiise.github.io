// 메뉴(#slide)·검색(#search)은 href 없는 <a role="button"> 이라 Enter 로 활성화되지
// 않고(WCAG 2.1.1), main.js 는 click 만 걸어 둔다. 그래서 검색은 키보드로 아예 열 수
// 없었고, Space 를 치면 문서 전역 핸들러가 대신 메뉴를 열었다.
//
// 이 코드가 인라인이 아니라 별도 파일인 이유가 있다. _layouts/compress.html 은
// <pre> 밖의 모든 공백을 `split:" " | join:" "` 로 뭉개는데, Ruby 의 String#split(" ")
// 은 개행까지 흡수한다. 인라인으로 두면 이 파일을 거치는 모든 페이지에서 스크립트가
// 한 줄이 되어 첫 // 주석이 나머지 전부를 삼킨다. 실제로 그렇게 넣었다가 홈과 목록
// 페이지에서 통째로 죽어 있었다.
//
// main.js(2018년 gulp 로 압축한 Zepto 번들, 원본은 src/js)는 손대지 않고 여기서 덮어
// 고친다. 압축본을 손으로 고치면 src/js 와 어긋나서 다음 사람이 원본을 믿을 수 없다.
(function () {
  var slide = document.getElementById('slide');
  var fade = document.getElementById('fade');
  var sidebar = document.getElementById('sidebar');
  var search = document.getElementById('search');
  var wrapper = document.querySelector('.search-wrapper');
  var form = document.querySelector('.search-form');
  var input = document.querySelector('.search-field');
  var closeBtn = document.querySelector('.icon-remove-sign');

  // 검색 닫기(X)는 <svg> 라 .click() 이 없다. 셋 다 같은 방법으로 click 을 흘려보낸다.
  function press(el) { el.dispatchEvent(new MouseEvent('click', { bubbles: true })); }

  [slide, search, closeBtn].forEach(function (el) {
    if (!el) return;
    el.addEventListener('keydown', function (e) {
      if (e.key !== 'Enter' && e.key !== ' ') return;
      e.preventDefault();
      // 전역 Space 핸들러가 끼어들어 검색 대신 메뉴를 여는 것을 막는다.
      e.stopPropagation();
      // main.js 의 #slide click 은 여는 동작뿐이다. 마우스로 X 를 누르면 닫히는 것은
      // 열린 동안 #fade 오버레이가 버튼을 덮어 클릭이 #fade 로 가기 때문이다. 키보드는
      // 그 오버레이를 거치지 않으므로, 열려 있으면 직접 #fade 로 보낸다.
      press(el === slide && sidebar.classList.contains('slide') ? fade : el);
    });
  });

  // 전역 단축키가 기본 동작을 가로채지 않게 한다(WCAG 2.1.1·2.1.4). main.js 는
  // document keydown 에서 어디서 누르든 Space 로 메뉴를 열고, window.onkeydown 은
  // body 의 Space 스크롤을 막는다. 그래서 Space 로 글을 넘겨 읽을 수 없었고, 링크에서
  // Space 를 누르면 스크롤과 함께 메뉴가 덮였다. window 캡처 단계에서 전파만 끊어 두
  // 핸들러 모두에 닿지 않게 하고, 기본 동작(스크롤·입력)은 그대로 둔다. 메뉴·검색
  // 버튼 위의 Space 는 위 keydown 이 처리하므로 통과시킨다. 숫자·문자 단축키는 메뉴가
  // 열려 있을 때만 동작하고 메뉴에 키가 적혀 있어 그대로 둔다.
  window.addEventListener('keydown', function (e) {
    if (e.key === ' ' && e.target !== slide && e.target !== search && e.target !== closeBtn) e.stopPropagation();
  }, true);

  if (form && input) {
    // main.js 는 검색이 열려 있으면 어떤 키든 뗄 때마다 입력칸에 focus() 를 다시 건다
    // (열 때 누른 's' 가 입력칸에 찍히지 않게 하려는 장치). 그래서 Tab 으로 X·결과로
    // 가도 keyup 에서 입력칸으로 끌려와 키보드로는 결과를 열 수 없었다(WCAG 2.1.1).
    // 포커스가 검색 패널 안(입력칸 제외)에 있을 때만 keyup 을 끊는다. 입력칸의 keyup 은
    // simpleJekyllSearch 가 결과를 그리는 데 쓰므로 살려 둔다. 패널 밖으로 Tab 하면
    // main.js 가 입력칸으로 되돌리므로 포커스가 오버레이 뒤로 빠지지 않고 패널 안을 돈다.
    window.addEventListener('keyup', function (e) {
      if (form.classList.contains('active') && e.target !== input && form.contains(e.target)) e.stopPropagation();
    }, true);
    // 닫힌 검색 패널은 transform·opacity 로 화면 밖에 밀려 있을 뿐이라 입력칸이 탭
    // 순서와 스크린리더에 남아 있었다. 모든 페이지에서 첫 Tab 이 보이지 않는 입력칸에
    // 갔다가 main.js 의 blur() 로 BODY 로 떨어졌다(WCAG 2.4.3·2.4.7). 열고 닫는 길이
    // 여럿이라(클릭·Enter·'s'·Escape·X) 클래스 변화를 지켜보고 inert 를 맞춘다.
    // MutationObserver 콜백은 click 직후 마이크로태스크로 돌아서, main.js 가 keyup 에서
    // 부르는 input.focus() 보다 먼저 inert 가 풀린다.
    var sync = function () { wrapper.inert = !form.classList.contains('active'); };
    sync();
    new MutationObserver(sync).observe(form, { attributes: true, attributeFilter: ['class'] });
  }

  // 메뉴 열림 상태를 스크린리더에 알린다. 여는 곳은 #slide, 닫는 곳은 #fade 뿐이다
  // (Escape 도 main.js 가 #fade 의 click 으로 흘려보낸다).
  if (slide && fade) {
    slide.addEventListener('click', function () { slide.setAttribute('aria-expanded', 'true'); });
    fade.addEventListener('click', function () {
      slide.setAttribute('aria-expanded', 'false');
      // 사이드바 안에서 Escape 로 닫으면 사이드바가 visibility:hidden 이 되면서 포커스가
      // BODY 로 떨어진다. 닫는 순간에는 아직 activeElement 가 사이드바 안에 있다.
      if (sidebar && sidebar.contains(document.activeElement)) slide.focus();
    });
  }
  // X 클릭·Enter·Escape 어느 쪽으로 닫아도 main.js 는 X 의 click 을 거친다. 포커스를
  // 검색을 연 버튼으로 돌려준다(전에는 BODY 로 떨어졌다).
  if (closeBtn && search) closeBtn.addEventListener('click', function () { search.focus(); });

  // simpleJekyllSearch 는 부를 때마다 search.json 을 새로 받고 입력칸에 keyup 핸들러를
  // 하나 더 붙인다. main.js 는 검색을 열 때마다 부르므로, 첫 호출만 통과시킨다.
  // 요청이 실패하면 다시 열 때 한 번 더 받게 되돌린다. keyup 핸들러는 성공 콜백에서만
  // 붙으므로 실패한 호출은 아무것도 남기지 않는다. Zepto 는 ajaxError 를 document 에 쏜다.
  var $ = window.Zepto;
  if ($ && $.fn.simpleJekyllSearch) {
    var initSearch = $.fn.simpleJekyllSearch;
    var once = function () {
      $.fn.simpleJekyllSearch = function () { return this; };
      return initSearch.apply(this, arguments);
    };
    $.fn.simpleJekyllSearch = once;
    $(document).on('ajaxError', function (e, xhr, opts) {
      if (/search\.json/.test(opts.url)) $.fn.simpleJekyllSearch = once;
    });
  }
})();
