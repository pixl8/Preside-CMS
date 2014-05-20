<cfscript>
	staticRoot       = getSetting( name="cfstatic_generated_url", defaultValue="/_assets" );
	ckeditorSettings = getSetting( name="ckeditor", defaultValue={} );


	event.includeData( {
		  ckeditorConfig             = staticRoot & ( ckeditorSettings.defaults.configFile ?: "/ckeditorExtensions/config.js" )
		, ckeditorDefaultToolbar     = ckeditorSettings.defaults.toolbar ?: ""
		, ckeditorDefaultWidth       = ckeditorSettings.defaults.width  ?: "auto"
		, ckeditorDefaultHeight      = ckeditorSettings.defaults.height ?: "auto"
		, ckeditorDefaultStyleSheets = ArrayToList( ckeditorSettings.defaults.stylesheets ?: [] )
	} );
</cfscript>

<cfoutput>
	<script type="text/javascript" src="#staticRoot#/ckeditor/ckeditor.js"></script>
</cfoutput>