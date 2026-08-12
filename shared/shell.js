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
