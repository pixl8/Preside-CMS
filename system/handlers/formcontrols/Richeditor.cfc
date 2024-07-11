/**
 * @feature presideForms
 */
component {
	property name="ckeditorToolbarHelper" inject="ckeditorToolbarHelper";
	property name="ckeditorSettings"      inject="coldbox:setting:ckeditor";
	property name="sticker"               inject="featureInjector:sticker:StickerForPreside";

	public string function index( event, rc, prc, args={} ) output=false {
		var toolbar = args.toolbar ?: "full";

		if ( Len( Trim( toolbar ) ) ) {
			args.toolbar = ckeditorToolbarHelper.getToolbarDefinition( toolbar );
		}

		if ( isFeatureEnabled( "sticker" ) ) {
			var stylesheets = args.stylesheets ?: Duplicate( ckeditorSettings.defaults.stylesheets ?: "" );
			if ( isSimpleValue( stylesheets ) ) {
				stylesheets = ListToArray( stylesheets );
			}

			for( var i=1; i <= stylesheets.len(); i++ ){
				stylesheets[i] = sticker.getAssetUrl( stylesheets[i] );
			}

			args.stylesheets = ArrayToList( stylesheets );
		}

		return renderView( view="formcontrols/richeditor/index", args=args );
	}
}