/* 0x00 site.js: progressive enhancement only. No innerHTML. */
(() => {
const d = document, b = d.body, $ = i => d.getElementById(i),
  prod = location.origin == 'https://snutiise.github.io';

// nav aria-current (x/index.html = x/)
d.querySelector('.site-nav a[href="' + b.dataset.nav + '"]')?.setAttribute('aria-current', location.pathname.replace(/\/index\.html$/, '/') == b.dataset.nav ? 'page' : 'true');

// TOC spy: raw href vs Hangul id (a.hash is encoded)
const toc = d.querySelector('.toc');
if (toc) {
 const r = toc.parentNode, hs = [];
 let on = null, q = 0;
 for (const a of toc.querySelectorAll('a')) {
  const h = $(a.getAttribute('href').slice(1));
  if (h) { hs.push([h, a]); a.className = h.className; } // h2.part -> bold entry
 }
 const spy = () => {
  let a = null;
  q = 0;
  for (const [h, l] of hs) { if (h.getBoundingClientRect().top >= innerHeight / 4) break; a = l; }
  if (scrollY && innerHeight + scrollY > d.documentElement.scrollHeight - 2) a = hs.at(-1)?.[1];
  if (a == on) return;
  on?.removeAttribute('aria-current');
  if (a) {
   a.setAttribute('aria-current', 'location');
   const t = a.offsetTop;
   if (t < r.scrollTop || t > r.scrollTop + r.clientHeight - 48) r.scrollTop = t - r.clientHeight / 3;
  }
  on = a;
 };
 addEventListener('scroll', () => q ||= requestAnimationFrame(spy));
 spy();
 const m = matchMedia('(min-width:64em)'), rail = () => toc.querySelector('summary').inert = m.matches && CSS.supports('selector(::details-content)');
 m.onchange = rail; rail();
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
   for (const li of ul.querySelectorAll('li')) {
    li.hidden = !(li.textContent + ' ' + li.dataset.q).toLowerCase().includes(t);
    if (!li.hidden) n++;
   }
   ul.closest('section').hidden = !ul.querySelector('li:not([hidden])');
  }
  $('filter-count').textContent = t ? n + '편' : '';
 });
}

// Disqus on click; no page.identifier. Posts and research pages. Research bodies are untrusted text: they can
// carry an id (heading, SVG) but never a <button> or data-*, so match tag + data-url, not the id alone
const btn = d.querySelector('button#load-comments'), th = d.querySelector('div#disqus_thread[data-url]');
if (btn && th) btn.addEventListener('click', () => {
 const n = d.querySelector('p#cm-note'), s = d.createElement('script');
 if (!prod) { n.textContent = '미리보기에서는 불러오지 않는다.'; n.hidden = false; return; }
 // embed.js reads window.disqus_<k> globals; an element id in content (e.g. a heading named disqus_identifier) would
 // clobber them through named access, so shadow them before configuring.
 for (const k of ['shortname', 'identifier', 'url', 'documentTitle', 'title', 'integration', 'integrationVersion', 'slug', 'category_id', 'container_id']) window['disqus_' + k] = undefined;
 window.disqus_config = function () { this.page.url = th.dataset.url; this.page.title = th.dataset.title; };
 s.src = 'https://snutiise.disqus.com/embed.js';
 s.dataset.timestamp = Date.now();
 b.append(s);
 btn.remove();
 th.tabIndex = -1;
 th.focus();
});

// Naver: production, blog only
if (prod && 'track' in b.dataset) {
 window.wcs_add = { wa: 'a4fc7be0d37ba' };
 const w = d.createElement('script');
 w.src = 'https://wcs.naver.net/wcslog.js';
 w.onload = () => window.wcs_do?.();
 d.head.append(w);
}
})();
