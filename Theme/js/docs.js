/*
 * Docs-specific interactions. The shared chrome (navbar dropdowns, dark-mode
 * toggle, syntax highlighting) is handled by design.vapor.codes/main.js; this
 * only covers the documentation body: the mobile sidebar drawer and the
 * on-this-page scroll-spy.
 */
(function () {
    "use strict";

    // --- Mobile sidebar drawer ------------------------------------------
    var sidebar = document.getElementById("kiln-sidebar");
    var toggle = document.getElementById("kiln-sidebar-toggle");
    var backdrop = document.getElementById("kiln-doc-backdrop");

    function openSidebar() {
        if (!sidebar) return;
        sidebar.classList.add("kiln-open");
        if (backdrop) backdrop.classList.add("kiln-open");
        if (toggle) toggle.setAttribute("aria-expanded", "true");
    }
    function closeSidebar() {
        if (!sidebar) return;
        sidebar.classList.remove("kiln-open");
        if (backdrop) backdrop.classList.remove("kiln-open");
        if (toggle) toggle.setAttribute("aria-expanded", "false");
    }

    if (toggle) {
        toggle.addEventListener("click", function () {
            if (sidebar && sidebar.classList.contains("kiln-open")) closeSidebar();
            else openSidebar();
        });
    }
    if (backdrop) backdrop.addEventListener("click", closeSidebar);
    document.addEventListener("keydown", function (e) {
        if (e.key === "Escape") closeSidebar();
    });
    // Close the drawer after following an in-page nav link on mobile.
    if (sidebar) {
        sidebar.addEventListener("click", function (e) {
            var link = e.target.closest("a.kiln-nav-link");
            if (link && window.matchMedia("(max-width: 800px)").matches) closeSidebar();
        });
    }

    // --- Search shortcuts -----------------------------------------------
    // `/` or ⌘K / Ctrl+K focuses the body search; Esc blurs it.
    var searchInput = document.getElementById("kiln-search-input");
    if (searchInput) {
        searchInput.setAttribute("placeholder", "Quick search");
        document.addEventListener("keydown", function (e) {
            var typing = /^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName) ||
                document.activeElement.isContentEditable;
            if ((e.key === "k" || e.key === "K") && (e.metaKey || e.ctrlKey)) {
                e.preventDefault();
                searchInput.focus();
                searchInput.select();
            } else if (e.key === "/" && !typing) {
                e.preventDefault();
                searchInput.focus();
            } else if (e.key === "Escape" && document.activeElement === searchInput) {
                searchInput.blur();
            }
        });
    }

    // --- On-this-page scroll-spy ----------------------------------------
    var tocLinks = Array.prototype.slice.call(
        document.querySelectorAll(".kiln-toc a[href^='#']")
    );
    if (tocLinks.length && "IntersectionObserver" in window) {
        var byId = {};
        var headings = [];
        tocLinks.forEach(function (link) {
            var id = decodeURIComponent(link.getAttribute("href").slice(1));
            var el = document.getElementById(id);
            if (el) {
                byId[id] = link;
                headings.push(el);
            }
        });

        var current = null;
        function setActive(id) {
            if (current === id) return;
            current = id;
            tocLinks.forEach(function (l) { l.classList.remove("kiln-toc-active"); });
            if (byId[id]) byId[id].classList.add("kiln-toc-active");
        }

        var observer = new IntersectionObserver(function (entries) {
            // Pick the topmost heading currently intersecting the upper viewport.
            var visible = entries
                .filter(function (e) { return e.isIntersecting; })
                .sort(function (a, b) { return a.boundingClientRect.top - b.boundingClientRect.top; });
            if (visible.length) setActive(visible[0].target.id);
        }, { rootMargin: "0px 0px -70% 0px", threshold: 0 });

        headings.forEach(function (h) { observer.observe(h); });
    }
})();
