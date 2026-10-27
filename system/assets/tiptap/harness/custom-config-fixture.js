/**
 * CKEditor-style custom config file - harness fixture for the facade's
 * customConfig support (see src/customConfig.js). Mirrors what a real site
 * override of settings.ckeditor.defaults.configFile looks like: some plugin
 * registration boilerplate (which must no-op harmlessly) plus a
 * CKEDITOR.editorConfig that sets real config.
 */
( function() {
	// The stock Preside config.js does this - it must not throw against the shim.
	var basePath = CKEDITOR.basePath + "../ckeditorExtensions/";
	CKEDITOR.plugins.addExternal( "widgets", basePath + "plugins/widgets/", "plugin.js" );
} )();

CKEDITOR.editorConfig = function( config ) {
	config.extraPlugins = "autogrow,widgets"; // CKEditor plugin loading - ignored

	// named toolbar, resolvable from data-toolbar="harnessCustom"
	config.toolbar_harnessCustom = [
		{ name: "basic", items: [ "Bold", "Italic" ] }
	];

	config.format_tags       = "p;h2";
	config.enterMode         = CKEDITOR.ENTER_BR;
	config.disallowedContent = "*{text-shadow*}";
};
