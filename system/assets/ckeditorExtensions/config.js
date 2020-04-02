(function() {
	var basePath = CKEDITOR.basePath + "../ckeditorExtensions/";
	basePath = basePath.replace( "ckeditor/../", "/" );

	// register our custom plugins
	CKEDITOR.plugins.addExternal( 'widgets'         , basePath+'plugins/widgets/'         , 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'imagepicker'     , basePath+'plugins/imagepicker/'     , 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'attachmentpicker', basePath+'plugins/attachmentpicker/', 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'presidelink'     , basePath+'plugins/presidelink/'     , 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'codesnippet'     , basePath+'plugins/codesnippet/'     , 'plugin.js' );
})();


CKEDITOR.editorConfig = function( config ) {
	// activate our plugins
	config.extraPlugins = "autogrow,widgets,imagepicker,attachmentpicker,presidelink,codesnippet";

	// configuring the auto imported styles from editor stylesheet (see stylesheetparser plugin)
	config.stylesSet = [];
	config.stylesheetParser_validSelectors = /^(h[1-6]|p|span|pre|li|ul|ol|dl|dt|dd|small|i|b|em|strong|table)\.\w+/;
};