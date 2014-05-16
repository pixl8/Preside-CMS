component output=false {
	property name="ckeditorToolbarHelper" inject="ckeditorToolbarHelper";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var toolbar = viewletArgs.toolbar ?: "full";
		if ( Len( Trim( toolbar ) ) ) {
			viewletArgs.toolbar = ckeditorToolbarHelper.getToolbarDefinition( toolbar );
		}

		return renderView( view="formcontrols/richeditor/index", args=viewletArgs );
	}

// private helpers
}