<cfscript>
	ckeditorSettings = getSetting( name="ckeditor", defaultValue={} );
	configFile       = ckeditorSettings.defaults.configFile ?: "/ckeditorExtensions/config.js";

	if ( FileExists( "/assets" & configFile ) ) {
		configFile = getSetting( name="static.siteAssetsUrl", defaultValue="/assets" ) & configFile;
	} else {
		configFile = event.buildLink( systemStaticAsset = configFile );
	}

	event.include( "ckeditor" );

	event.includeData( {
		  ckeditorConfig             = configFile
		, ckeditorDefaultToolbar     = ckeditorSettings.defaults.toolbar   ?: ""
		, ckeditorDefaultWidth       = ckeditorSettings.defaults.width     ?: "auto"
		, ckeditorDefaultMinHeight   = ckeditorSettings.defaults.minHeight ?: "auto"
		, ckeditorDefaultMaxHeight   = ckeditorSettings.defaults.maxHeight ?: 300
	} );
</cfscript>