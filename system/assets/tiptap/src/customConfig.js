/**
 * CKEditor custom-config-file support.
 *
 * Preside points every editor at a config file (`settings.ckeditor.defaults.configFile`,
 * overridable per field via the `customConfig` form-control attribute ->
 * `data-custom-config`; the resolved URL for the global one arrives as
 * `cfrequest.ckeditorConfig`). Real CKEditor loads that JS file and calls its
 * `CKEDITOR.editorConfig( config )` - whatever it sets becomes the BASE config,
 * overridden by everything Preside sets per instance (toolbar, defaultConfigs,
 * data-* attributes). We reproduce that: fetch the file, execute it, capture
 * `CKEDITOR.editorConfig`, run it once against a fresh object, and cache the
 * resulting config per URL.
 *
 * The stock Preside file (/ckeditorExtensions/config.js) only registers CKEditor
 * plugins (CKEDITOR.plugins.addExternal + config.extraPlugins) - executing it is
 * harmless: the shim below no-ops the plugin registry and plugin-loading keys
 * are simply never consumed. Site-provided files typically set real config
 * (toolbar_* definitions, format_tags, disallowedContent, enterMode, contentsCss,
 * stylesSet...) and those ARE honoured.
 *
 * Timing: frontendEditors does `new PresideRichEditor( el ).editor` synchronously,
 * so init cannot wait on a network callback. The facade prefetches the global
 * config file at script-parse time (async); getCustomConfig() then falls back to
 * a synchronous same-origin XHR only if the cache is still cold (rare - and the
 * browser cache makes it cheap even then).
 */

var cache = {}; // url -> config object produced by the file's editorConfig()

// The bits of the CKEDITOR global that config files conventionally touch.
function ckShim() {
	var CK = window.CKEDITOR = window.CKEDITOR || {};
	if ( typeof CK.basePath !== "string" ) { CK.basePath = "/"; }
	CK.plugins = CK.plugins || {};
	if ( typeof CK.plugins.addExternal !== "function" ) { CK.plugins.addExternal = function() {}; }
	if ( typeof CK.plugins.add         !== "function" ) { CK.plugins.add         = function() {}; }
	return CK;
}

// Execute the file source, capture the CKEDITOR.editorConfig it assigns, and
// collect the config it produces. Never throws - a broken file must not stop
// editors from mounting (matching CKEditor, where a script error just means an
// unconfigured editor).
function execute( src ) {
	var CK     = ckShim();
	var prev   = CK.editorConfig;
	var config = {};
	CK.editorConfig = null;
	try {
		new Function( src )();
		if ( typeof CK.editorConfig === "function" ) { CK.editorConfig( config ); }
	} catch ( e ) {
		if ( window.console ) { window.console.warn( "[tiptap] custom config file threw - ignoring it", e ); }
		config = {};
	}
	CK.editorConfig = prev;
	return config;
}

// Async warm-up; safe to call speculatively (no-ops on falsy/already-cached URLs).
export function prefetchCustomConfig( url ) {
	if ( !url || Object.prototype.hasOwnProperty.call( cache, url ) ) { return; }
	try {
		var xhr = new XMLHttpRequest();
		xhr.open( "GET", url, true );
		xhr.onload = function() {
			if ( !Object.prototype.hasOwnProperty.call( cache, url ) ) {
				cache[ url ] = xhr.status >= 200 && xhr.status < 300 ? execute( xhr.responseText ) : {};
			}
		};
		xhr.onerror = function() {
			if ( !Object.prototype.hasOwnProperty.call( cache, url ) ) { cache[ url ] = {}; }
		};
		xhr.send();
	} catch ( e ) {}
}

// Resolve the config for a URL, synchronously. Returns {} for no URL / fetch or
// execution failure. First call per URL blocks on a same-origin XHR unless the
// prefetch has already landed.
export function getCustomConfig( url ) {
	if ( !url ) { return {}; }
	if ( Object.prototype.hasOwnProperty.call( cache, url ) ) { return cache[ url ]; }
	var config = {};
	try {
		var xhr = new XMLHttpRequest();
		xhr.open( "GET", url, false );
		xhr.send();
		if ( xhr.status >= 200 && xhr.status < 300 ) { config = execute( xhr.responseText ); }
	} catch ( e ) {
		if ( window.console ) { window.console.warn( "[tiptap] could not load custom config file", url, e ); }
	}
	cache[ url ] = config;
	return config;
}
