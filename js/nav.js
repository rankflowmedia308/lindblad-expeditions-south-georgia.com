const btn = document.querySelector('.nav-toggle');
const nav = document.querySelector('.site-nav');
btn?.addEventListener('click', () => {
  const open = btn.getAttribute('aria-expanded') === 'true';
  btn.setAttribute('aria-expanded', String(!open));
  nav.classList.toggle('is-open');
});
