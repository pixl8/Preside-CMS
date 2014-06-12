<cfscript>
	ckeditorSettings = getSetting( name="ckeditor", defaultValue={} );

	event.include( "ckeditor" );

	event.includeData( {
		  ckeditorConfig             = event.buildLink( systemStaticAsset = "/ckeditorExtensions/config.js" )
		, ckeditorDefaultToolbar     = ckeditorSettings.defaults.toolbar   ?: ""
		, ckeditorDefaultWidth       = ckeditorSettings.defaults.width     ?: "auto"
		, ckeditorDefaultMinHeight   = ckeditorSettings.defaults.minHeight ?: "auto"
		, ckeditorDefaultMaxHeight   = ckeditorSettings.defaults.maxHeight ?: 600
	} );
</cfscript>