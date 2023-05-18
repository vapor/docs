// data-md-component="toc"
document.addEventListener("DOMContentLoaded", function(event) {
	var toc_inner = document.querySelectorAll('.md-sidebar__inner')[1];
	var script = document.createElement("script");
	script.src = '//cdn.carbonads.com/carbon.js?serve=CK7DT2QW&placement=vaporcodes';
	script.type = 'text/javascript';
	script.id = '_carbonads_js';

	if(typeof toc_inner !== undefined && window.innerWidth > 960) {
		toc_inner.appendChild(script);
	}
});
