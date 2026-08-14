/*
  Simetrik Agéntico — shared shell behavior (sidebar, nav, microinteracciones)
  Compartido entre flujos (home, y futuros: agents, apps).
*/

document.addEventListener('DOMContentLoaded', () => {
  if (window.lucide) lucide.createIcons();

  initSidebarCollapse();
  initProjectExpand();
  initNavActive();
  initSectionCollapse();
  initSidebarProjectActions();
});

function initSidebarCollapse() {
  const sidebar = document.getElementById('sidebar');
  const collapseBtn = document.getElementById('sidebarToggle'); // header icon, visible when expanded — "Close Side Panel"
  const expandBtn = document.getElementById('sidebarLogoExpand'); // logo, visible when collapsed — "Open Side Panel"
  if (!sidebar) return;

  function toggleSidebar() {
    sidebar.classList.toggle('is-collapsed');
  }

  if (collapseBtn) collapseBtn.addEventListener('click', toggleSidebar);
  if (expandBtn) expandBtn.addEventListener('click', toggleSidebar);
}

function initProjectExpand() {
  document.querySelectorAll('.project-row').forEach((row) => {
    row.addEventListener('click', () => {
      const item = row.closest('.project-item');
      if (item) item.classList.toggle('is-expanded');
    });
  });
}

function initSectionCollapse() {
  document.querySelectorAll('.sidebar-section-header').forEach((header) => {
    header.addEventListener('click', () => {
      const section = header.closest('.sidebar-section--collapsible');
      if (section) section.classList.toggle('is-expanded');
    });
  });
}

// Per-project ellipsis in the sidebar's Pinned section: opens a popover with
// Unpin/Invite members/Archive/Edit info. None of these actions are wired to
// real behavior yet — they're placeholders added ahead of defining what each
// one actually triggers (see docs/sidebar.md → Pendiente/abierto).
//
// The popover itself is a portal: it lives as a sibling of .app-shell near
// the end of <body> (matched to its trigger via data-sidebar-actions-menu /
// data-sidebar-actions-trigger, same project id), NOT nested inside the
// Pinned list. The Pinned list sits inside three nested overflow-clipping
// ancestors (.sidebar-section's own scroll, plus .sidebar-section-body/
// -body-inner's overflow:hidden for the collapse animation) — an
// overflow!=visible ancestor clips a descendant popover no matter what
// position value it uses, so portaling out of that subtree is the only
// reliable fix. Opens to the trigger's right (not below it), computed from
// getBoundingClientRect() since `position: fixed` needs real coordinates
// once the element isn't nested where CSS could anchor it with top/right.
function initSidebarProjectActions() {
  const triggers = Array.from(document.querySelectorAll('[data-sidebar-actions-trigger]'));
  if (!triggers.length) return;

  const POPOVER_GAP = 6; // space between the trigger's right edge and the popover
  const VIEWPORT_MARGIN = 8; // never render flush against the window edge

  function closeAllSidebarActionMenus() {
    document.querySelectorAll('.sidebar-project-actions-menu.is-open').forEach((menu) => menu.classList.remove('is-open'));
    document.querySelectorAll('.sidebar-project-actions-btn.is-open').forEach((btn) => btn.classList.remove('is-open'));
  }

  function openSidebarActionMenu(trigger, menu) {
    closeAllSidebarActionMenus();
    menu.classList.add('is-open');
    trigger.classList.add('is-open');

    const rect = trigger.getBoundingClientRect();
    let left = rect.right + POPOVER_GAP;
    let top = rect.top;

    // Clamp against the viewport, not against the sidebar — the popover
    // lives at <body> level now, so nothing about the sidebar's own width
    // constrains it, only the actual window edges do.
    const menuRect = menu.getBoundingClientRect(); // safe to measure now, display:block already applied via .is-open
    if (left + menuRect.width > window.innerWidth - VIEWPORT_MARGIN) {
      left = rect.left - menuRect.width - POPOVER_GAP; // not enough room to the right — flip to the left of the trigger instead
    }
    if (top + menuRect.height > window.innerHeight - VIEWPORT_MARGIN) {
      top = window.innerHeight - VIEWPORT_MARGIN - menuRect.height;
    }
    top = Math.max(VIEWPORT_MARGIN, top);

    menu.style.left = `${Math.round(left)}px`;
    menu.style.top = `${Math.round(top)}px`;
  }

  triggers.forEach((trigger) => {
    const id = trigger.getAttribute('data-sidebar-actions-trigger');
    const menu = document.querySelector(`.sidebar-project-actions-menu[data-sidebar-actions-menu="${id}"]`);
    if (!menu) return;

    trigger.addEventListener('click', (e) => {
      e.stopPropagation(); // stop this from immediately re-closing via the document listener below
      const isOpen = menu.classList.contains('is-open');
      closeAllSidebarActionMenus();
      if (!isOpen) openSidebarActionMenu(trigger, menu);
    });

    // Clicking an option doesn't do anything real yet — just closes the
    // popover, same as every other not-yet-wired action in this prototype.
    menu.addEventListener('click', (e) => {
      e.stopPropagation();
      if (e.target.closest('[data-sidebar-action]')) closeAllSidebarActionMenus();
    });
  });

  document.addEventListener('click', closeAllSidebarActionMenus);
  // The popover's position is a one-time snapshot of the trigger's
  // coordinates — if the Pinned list (or the page) scrolls or the window
  // resizes, that snapshot goes stale. Closing is simpler and safer here
  // than re-tracking position live for a menu whose actions are all no-ops
  // anyway. `true` = capture phase, since scroll doesn't bubble but this
  // still needs to hear about scrolls from inside .sidebar-section.
  document.addEventListener('scroll', closeAllSidebarActionMenus, true);
  window.addEventListener('resize', closeAllSidebarActionMenus);
}

function initNavActive() {
  document.querySelectorAll('.nav-item[data-nav]').forEach((item) => {
    item.addEventListener('click', (e) => {
      // el botón "+" interno maneja su propio click, no debe togglear el nav padre
      if (e.target.closest('.nav-item-add')) return;
      document.querySelectorAll('.nav-item[data-nav]').forEach((n) => n.classList.remove('is-active'));
      item.classList.add('is-active');
      const section = item.getAttribute('data-nav');
      if (typeof window.onNavSectionChange === 'function') {
        window.onNavSectionChange(section);
      }
    });
  });
}
