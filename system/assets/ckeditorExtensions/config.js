(function() {
	var basePath = CKEDITOR.basePath + "../ckeditorExtensions/";
	basePath = basePath.replace( "ckeditor/../", "/" );

	// register our custom plugins
	CKEDITOR.plugins.addExternal( 'widgets'         , basePath+'plugins/widgets/'         , 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'imagepicker'     , basePath+'plugins/imagepicker/'     , 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'attachmentpicker', basePath+'plugins/attachmentpicker/', 'plugin.js' );
	CKEDITOR.plugins.addExternal( 'presidelink'     , basePath+'plugins/presidelink/'     , 'plugin.js' );
})();


CKEDITOR.editorConfig = function( config ) {
	// activate our plugins
	config.extraPlugins = "widgets,imagepicker,attachmentpicker,stylesheetparser,presidelink";

	// the skin we are using
	config.skin = "bootstrapck";

	// configuring the auto imported styles from editor stylesheet (see stylesheetparser plugin)
	config.stylesSet = [];
	config.stylesheetParser_validSelectors = /^(h[1-6]|p|span|pre|li|ul|ol|dl|dt|dd|small|i|b|em|strong|table)\.\w+/;

	// Set the most common block elements.
	config.format_tags = 'p;h1;h2;h3;h4;h5;h6;pre;div';

	// auto grow config
	config.autoGrow_onStartup = true;

	// turn that damned auto P tag feature off!
	config.autoParagraph = false;

	// email obfuscation for link plugin
	config.emailProtection = 'encode';

	config.scayt_sLang = "en_GB";
};
