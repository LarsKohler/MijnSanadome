/**
 * MijnSanadome – Idle Lock
 *
 * Vergrendelt het scherm automatisch na een instelbare periode van
 * inactiviteit. Slaat gebruikersgegevens op in sessionStorage zodat
 * het lock-scherm (lock.html) de juiste naam, avatar en e-mail kan tonen.
 *
 * Gebruik:
 *   <script src="idle-lock.js"></script>
 *
 * De timer reset bij muis-, toetsenbord-, scroll- en aanraakgebeurtenissen.
 * Standaard timeout: 5 minuten (300 000 ms). Pas IDLE_TIMEOUT aan om dit
 * te wijzigen.
 *
 * Je kunt IdleLock.setUser({ email, userName, initials, avatarUrl })
 * aanroepen vanuit je auth-script om de gebruikersdata beschikbaar te maken
 * voor het lock-scherm.
 */
(function () {
  'use strict';

  // ─── Configuratie ───
  var IDLE_TIMEOUT = 5 * 60 * 1000;  // 5 minuten
  var STORAGE_KEY  = 'msn_lock';
  var EVENTS       = ['mousemove', 'mousedown', 'keydown', 'scroll', 'touchstart', 'click'];

  var _timer = null;
  var _userData = null;
  var _active = true;

  // Niet draaien op index.html (login) of lock.html zelf
  var currentPage = location.pathname.split('/').pop() || '';
  if (currentPage === 'index.html' || currentPage === 'lock.html' || currentPage === '') {
    return;
  }

  // ─── Timer logica ───
  function resetTimer() {
    if (!_active) return;
    if (_timer) clearTimeout(_timer);
    _timer = setTimeout(lockScreen, IDLE_TIMEOUT);
  }

  function lockScreen() {
    _active = false;

    // Probeer user data van NavCache te halen als setUser niet is aangeroepen
    if (!_userData) {
      try {
        var cached = JSON.parse(sessionStorage.getItem('msn_nav') || '{}');
        if (cached && cached.userName) {
          _userData = {
            userName: cached.userName || '',
            initials: cached.initials || '',
            avatarUrl: cached.avatarUrl || '',
            email: cached.email || ''
          };
        }
      } catch (e) { /* ok */ }
    }

    // Sla lock-data op
    var lockData = {
      returnUrl: location.pathname.split('/').pop() + location.search + location.hash,
      lockedAt: new Date().toISOString(),
      email: (_userData && _userData.email) || '',
      userName: (_userData && _userData.userName) || '',
      initials: (_userData && _userData.initials) || '',
      avatarUrl: (_userData && _userData.avatarUrl) || ''
    };

    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(lockData));
    } catch (e) { /* quota */ }

    // Redirect naar lock-scherm
    window.location.href = 'lock.html';
  }

  function start() {
    _active = true;
    EVENTS.forEach(function (evt) {
      document.addEventListener(evt, resetTimer, { passive: true });
    });
    // Luister ook naar visibility changes
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') {
        resetTimer();
      }
    });
    resetTimer();
  }

  // ─── Publieke API ───
  function setUser(data) {
    _userData = data || null;
  }

  function stop() {
    _active = false;
    if (_timer) clearTimeout(_timer);
    EVENTS.forEach(function (evt) {
      document.removeEventListener(evt, resetTimer);
    });
  }

  // Exporteer als globaal object
  window.IdleLock = {
    start: start,
    stop: stop,
    setUser: setUser,
    lock: lockScreen  // handmatige vergrendeling
  };

  // Start automatisch
  start();
})();
