component output=false {
	property name="ckeditorToolbarHelper" inject="ckeditorToolbarHelper";
	property name="ckeditorSettings"      inject="coldbox:setting:ckeditor";
	property name="cfstatic"              inject="coldbox:myPlugin:cfstaticForPreside";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var toolbar     = viewletArgs.toolbar ?: "full";
		var stylesheets = viewletArgs.stylesheets ?: Duplicate( ckeditorSettings.defaults.stylesheets ?: "" );
		if ( isSimpleValue( stylesheets ) ) {
			stylesheets = ListToArray( stylesheets );
		}

		for( var i=1; i <= stylesheets.len(); i++ ){
			stylesheets[i] = cfstatic.getIncludeUrl( "css", stylesheets[i] );
		}

		viewletArgs.stylesheets = ArrayToList( stylesheets );
		if ( Len( Trim( toolbar ) ) ) {
			viewletArgs.toolbar = ckeditorToolbarHelper.getToolbarDefinition( toolbar );
		}

		return renderView( view="formcontrols/richeditor/index", args=viewletArgs );
	}

// private helpers
}