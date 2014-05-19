(function() {
	var basePath = CKEDITOR.basePath + "../ckeditorExtensions/";
	basePath = basePath.replace( "ckeditor/../", "/" );

	// register our custom plugins
	CKEDITOR.plugins.addExternal( 'widgets', basePath+'plugins/widgets/', 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'imagepicker', basePath+'plugins/imagepicker/', 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'attachmentpicker', basePath+'plugins/attachmentpicker/', 'plugin.js' );
})();


CKEDITOR.editorConfig = function( config ) {
	// activate out plugins
	config.extraPlugins = "widgets,imagepicker,attachmentpicker";

	config.toolbar = "full"; // default toolbar

	// Set the most common block elements.
	config.format_tags = 'p;h1;h2;h3;pre';

	// 'cos the <p> tag functionality is just horrible
	config.enterMode = CKEDITOR.ENTER_BR;

	config.skin = "bootstrapck";
};
