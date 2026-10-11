/* 0x00 site.js: progressive enhancement only. No innerHTML. */
(() => {
const d = document, b = d.body, $ = i => d.getElementById(i),
  prod = location.origin == 'https://snutiise.github.io';

// nav aria-current
d.querySelector('.site-nav a[href="' + b.dataset.nav + '"]')?.setAttribute('aria-current', location.pathname == b.dataset.nav ? 'page' : 'true');

// TOC spy: raw href vs Hangul id (a.hash is encoded)
const toc = d.querySelector('.toc');
if (toc) {
 const r = toc.parentNode, hs = [];
 let on = null, q = 0;
 for (const a of toc.querySelectorAll('a')) {
  const h = $(a.getAttribute('href').slice(1));
  if (h) hs.push([h, a]);
 }
 const spy = () => {
  let a = null;
  q = 0;
  for (const [h, l] of hs) { if (h.getBoundingClientRect().top >= innerHeight / 4) break; a = l; }
  if (a == on) return;
  if (on) on.removeAttribute('aria-current');
  if (a) {
   a.setAttribute('aria-current', 'location');
   const t = a.offsetTop;
   if (t < r.scrollTop || t > r.scrollTop + r.clientHeight - 48) r.scrollTop = t - r.clientHeight / 3;
  }
  on = a;
 };
 addEventListener('scroll', () => { if (!q) { q = 1; requestAnimationFrame(spy); } });
 spy();
 d.addEventListener('click', e => { if (e.target.closest('a[href="#toc"]')) toc.open = true; });
}

// /posts/ filter
const f = $('post-filter');
if (f) {
 f.closest('.filter').hidden = false;
 f.addEventListener('input', () => {
  const t = f.value.trim().toLowerCase();
  let n = 0;
  for (const ul of d.querySelectorAll('.ls[data-filter]')) {
   let any = false;
   for (const li of ul.querySelectorAll('li')) {
    li.hidden = !(li.textContent + ' ' + li.dataset.tags).toLowerCase().includes(t);
    if (!li.hidden) { n++; any = true; }
   }
   ul.closest('section').hidden = !any;
  }
  $('filter-count').textContent = t ? n + '편' : '';
 });
}

// Disqus on click; no page.identifier
const btn = $('load-comments');
if (btn) btn.addEventListener('click', () => {
 const th = $('disqus_thread'), n = $('cm-note'), s = d.createElement('script');
 if (!prod) { n.textContent = '미리보기에서는 불러오지 않는다.'; n.hidden = false; return; }
 window.disqus_config = function () { this.page.url = th.dataset.url; this.page.title = th.dataset.title; };
 s.src = 'https://snutiise.disqus.com/embed.js';
 s.dataset.timestamp = Date.now();
 b.append(s);
 btn.remove();
 th.tabIndex = -1;
 th.focus();
});

// Naver + counter: production, blog only
if (prod && 'track' in b.dataset) {
 window.wcs_add = { wa: 'a4fc7be0d37ba' };
 const w = d.createElement('script'), x = new XMLHttpRequest();
 w.src = 'https://wcs.naver.net/wcslog.js';
 w.onload = () => window.wcs_do?.();
 d.head.append(w);
 x.onload = () => { // "total,ip,n": never show the IP
  const v = x.responseText.trim().split(',')[0], el = $('hits');
  if ((x.status == 200 || x.status == 201) && /^\d+$/.test(v) && el) { el.textContent = v + ' Hit!'; el.hidden = false; }
 };
 x.open('GET', 'https://us-central1-gitblog-885f6.cloudfunctions.net/countVisitor');
 x.send();
}
})();
