<!---@feature tiptapEditor--->
<cfscript>
	ckeditorSettings = getSetting( name="ckeditor", defaultValue={} );
	configFile       = ckeditorSettings.defaults.configFile ?: "/ckeditorExtensions/config.js";
	configFileName   = listFirst( configFile, "?" );
	tiptapI18nKeys   = getSetting( name="tiptap.i18nKeys", defaultValue=[] );
	tiptapI18n       = {};
	tiptapI18nKey    = "";
	tiptapI18nBundle = "";
	tiptapI18nJsKey  = "";

	if ( FileExists( "/assets" & configFileName ) ) {
		configFile = getSetting( name="static.siteAssetsUrl", defaultValue="/assets" ) & configFile;
	} else {
		configFile = event.buildLink( systemStaticAsset = configFile );
	}

	event.include( "tiptap" )
	     .include( "tiptap-facade" )
	     .include( "tiptap-css" );

	for ( tiptapI18nKey in tiptapI18nKeys ) {
		if ( listLen( tiptapI18nKey, ":" ) > 1 ) {
			tiptapI18nBundle = listFirst( tiptapI18nKey, ":" );
			tiptapI18nJsKey  = listRest(  tiptapI18nKey, ":" );
		} else {
			tiptapI18nBundle = "tiptap";
			tiptapI18nJsKey  = tiptapI18nKey;
		}
		tiptapI18n[ tiptapI18nJsKey ] = translateResource( uri="#tiptapI18nBundle#:#tiptapI18nJsKey#", defaultValue="" );
	}

	event.includeData( {
		  tiptapI18n               = tiptapI18n
		, tiptapWidgets            = args.tiptapWidgets ?: []
		, richeditorEngine         = "tiptap"
		, ckeditorConfig           = configFile
		, ckeditorDefaultToolbar   = ckeditorSettings.defaults.toolbar        ?: ""
		, ckeditorDefaultWidth     = ckeditorSettings.defaults.width          ?: "auto"
		, ckeditorDefaultMinHeight = ckeditorSettings.defaults.minHeight      ?: "auto"
		, ckeditorDefaultMaxHeight = ckeditorSettings.defaults.maxHeight      ?: 300
		, ckeditorAutoParagraph    = ckeditorSettings.defaults.autoParagraph  ?: true
		, ckeditorDefaultConfigs   = ckeditorSettings.defaults.defaultConfigs ?: {}
	} );
</cfscript>
