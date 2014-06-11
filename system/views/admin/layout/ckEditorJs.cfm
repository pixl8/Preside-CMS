<cfscript>
	staticRoot       = event.getSystemAssetsUrl();
	ckeditorSettings = getSetting( name="ckeditor", defaultValue={} );

	event.include( "ckeditor" );

	event.includeData( {
		  ckeditorConfig             = staticRoot & ( ckeditorSettings.defaults.configFile ?: "/ckeditorExtensions/config.js" )
		, ckeditorDefaultToolbar     = ckeditorSettings.defaults.toolbar   ?: ""
		, ckeditorDefaultWidth       = ckeditorSettings.defaults.width     ?: "auto"
		, ckeditorDefaultMinHeight   = ckeditorSettings.defaults.minHeight ?: "auto"
		, ckeditorDefaultMaxHeight   = ckeditorSettings.defaults.maxHeight ?: 600
	} );
</cfscript>