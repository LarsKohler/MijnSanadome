/**
 * MijnSanadome – Instant Navigation Cache
 *
 * Slaat auth-/permissiedata op in sessionStorage na de eerste Supabase-check.
 * Bij volgende pagina-navigatie wordt de sidebar, topbar en permissies direct
 * vanuit de cache gerenderd – zonder te wachten op Supabase – zodat er geen
 * laadvertraging zichtbaar is tussen pagina's.
 *
 * Gebruik:
 *   var cached = NavCache.load();          // null of { userName, ... }
 *   NavCache.save({ userName, ... });      // na auth-check
 *   NavCache.applyUI(cached);             // render sidebar + topbar direct
 *   NavCache.clear();                     // bij uitloggen
 */
(function () {
  'use strict';
  var KEY = 'msn_nav';

  function save(data) {
    try { sessionStorage.setItem(KEY, JSON.stringify(data)); } catch (e) { /* quota */ }
  }

  function load() {
    try {
      var raw = sessionStorage.getItem(KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (e) { return null; }
  }

  function clear() {
    try { sessionStorage.removeItem(KEY); } catch (e) { /* ok */ }
  }

  /**
   * Pas UI direct toe vanuit cache-data
   * @param {Object} d - { userName, initials, avatarUrl, role, perms }
   */
  function applyUI(d) {
    if (!d) return;

    // Topbar user info
    var nameEl = document.getElementById('user-name');
    if (nameEl) nameEl.textContent = d.userName || 'Laden…';

    var roleEl = document.getElementById('user-role-label') || document.getElementById('user-role');
    if (roleEl) roleEl.textContent = d.role || 'Medewerker';

    var avatarEl = document.getElementById('user-avatar');
    if (avatarEl) {
      if (d.avatarUrl) {
        avatarEl.innerHTML = '<img src="' + d.avatarUrl + '" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">';
      } else if (d.initials) {
        avatarEl.textContent = d.initials;
      }
    }

    // Profile avatar (dashboard)
    var profileInitials = document.getElementById('profile-initials');
    if (profileInitials) {
      if (d.avatarUrl) {
        profileInitials.innerHTML = '<img src="' + d.avatarUrl + '" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">';
      } else if (d.initials) {
        profileInitials.textContent = d.initials;
      }
    }

    // Greeting (dashboard)
    var profileName = document.getElementById('profile-name');
    if (profileName && d.userName) {
      var hour = new Date().getHours();
      var greeting = hour < 12 ? 'Goedemorgen' : hour < 18 ? 'Goedemiddag' : 'Goedenavond';
      profileName.textContent = greeting + ', ' + d.userName;
    }

    // Permissions – verberg elementen
    if (d.perms) {
      document.querySelectorAll('[data-permission]').forEach(function (el) {
        var k = el.getAttribute('data-permission');
        if (d.perms[k] === false) el.style.display = 'none';
      });
    }

    // Sidebar active state
    var currentPage = location.pathname.split('/').pop() || 'dashboard.html';
    document.querySelectorAll('.sidebar-nav .nav-item').forEach(function (a) {
      var href = (a.getAttribute('href') || '').split('/').pop();
      if (href === currentPage || (currentPage === '' && href === 'dashboard.html')) {
        a.classList.add('active');
      } else {
        a.classList.remove('active');
      }
    });

    // Toon pagina direct (geen loader nodig)
    document.body.classList.add('app-ready');
  }

  /**
   * Prerender interne pagina's via Speculation Rules API (Chrome/Edge 109+).
   * Fallback: prefetch voor andere browsers.
   */
  function prerenderPages() {
    var pages = ['dashboard.html', 'gebruikers.html', 'nieuws.html', 'debiteuren.html',
      'rechten.html', 'profiel.html', 'onboarding.html', 'artikel.html'];
    var current = location.pathname.split('/').pop() || 'dashboard.html';
    var targets = pages.filter(function (p) { return p !== current; });

    // Speculation Rules API – prerenders volledig in achtergrond
    if (HTMLScriptElement.supports && HTMLScriptElement.supports('speculationrules')) {
      var rules = { prerender: [{ urls: targets, eagerness: 'moderate' }] };
      var script = document.createElement('script');
      script.type = 'speculationrules';
      script.textContent = JSON.stringify(rules);
      document.head.appendChild(script);
      return;
    }

    // Fallback: prefetch
    targets.forEach(function (p) {
      var link = document.createElement('link');
      link.rel = 'prefetch';
      link.href = p;
      link.as = 'document';
      document.head.appendChild(link);
    });
  }

  // Start prerender/prefetch na idle
  if ('requestIdleCallback' in window) {
    requestIdleCallback(prerenderPages);
  } else {
    setTimeout(prerenderPages, 200);
  }

  window.NavCache = { save: save, load: load, clear: clear, applyUI: applyUI };
})();
