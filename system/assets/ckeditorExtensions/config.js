(function() {
	var basePath = CKEDITOR.basePath + "../ckeditorExtensions/";
	basePath = basePath.replace( "ckeditor/../", "/" );

	// register our custom plugins
	CKEDITOR.plugins.addExternal( 'widgets', basePath+'plugins/widgets/', 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'imagepicker', basePath+'plugins/imagepicker/', 'plugin.js' );
})();


CKEDITOR.editorConfig = function( config ) {
	// activate out plugins
	config.extraPlugins = "widgets,imagepicker";


	config.toolbar = "";

	config.toolbar = "full"; // default toolbar

	// Remove some buttons provided by the standard plugins, which are
	// not needed in the Standard(s) toolbar.
	config.removeButtons = 'Underline,Subscript,Superscript';

	// Set the most common block elements.
	config.format_tags = 'p;h1;h2;h3;pre';

	// Simplify the dialog windows.
	config.removeDialogTabs = 'image:advanced;link:advanced';

	// 'cos the <p> tag functionality is just horrible
	config.enterMode = CKEDITOR.ENTER_BR;


	config.skin = "bootstrapck";
};
