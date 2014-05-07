component output=false {

	property name="siteTreeService" inject="siteTreeService";

	public string function index( event, rc, prc, viewletArgs={} ) output=false {
		var value = event.getValue(
			  name         = viewletArgs.name ?: ""
			, defaultValue = viewletArgs.defaultValue ?: ""
		);

		if ( not IsSimpleValue( value ) ) {
			value = "";
		}

		if ( Len( Trim ( value ) ) ) {
			viewletArgs.selectedPage = siteTreeService.getPage( id = value, includeInactive=true );
		}

		return renderView( view="formcontrols/sitetreePagePicker/index", args=viewletArgs );
	}
}