component {

	private string function admin( event, rc, prc, args={} ) {
		args.remoteUrl   = event.buildLink( linkTo="formcontrols.IconPicker.ajaxGetIcons", querystring="q=%QUERY" );
		args.prefetchUrl = event.buildLink( linkTo="formcontrols.IconPicker.ajaxGetIcons" );

		return renderView( view="formcontrols/iconPicker/index", args=args );
	}

	public void function ajaxGetIcons( event, rc, prc ) {
		var query = rc.q ?: "";
		var data  = [];

		var allIcons = getSetting( "formControls.iconPicker.icons" );
		var icons    = [];

		if ( isEmptyString( query ) ) {
			icons = allIcons;
		} else {
			icons = ArrayFilter( allIcons, function( item ) {
				return ArrayLen( ReMatchNoCase( query, item ) ) > 0;
			} );
		}

		for ( var icon in icons ) {
			ArrayAppend( data, {
				  text      = translateResource( uri="formControls.iconPicker:#icon#.label"    , defaultValue=icon )
				, iconClass = translateResource( uri="formControls.iconPicker:#icon#.iconClass", defaultValue="" )
				, value     = icon
			} );
		}

		event.renderData( type="json", data=data );
	}

}