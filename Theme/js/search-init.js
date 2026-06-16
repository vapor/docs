// Bootstraps Kiln's client-side search/version globals from data- attributes on
// <body>. Kept as an external file (rather than an inline <script> with the
// per-page values interpolated) so the Content-Security-Policy needs no
// 'unsafe-inline' for scripts. Must run before search.js, which reads
// window.kilnSearchIndex synchronously at load.
(function () {
    var data = document.body.dataset;
    window.kilnSearchIndex = data.searchIndex;
    window.kilnVersionBase = data.versionBase || "";
})();
