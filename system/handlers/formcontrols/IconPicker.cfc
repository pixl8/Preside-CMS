component {

	private string function admin( event, rc, prc, args={} ) {
		args.context = "admin";

		return index( argumentCollection=arguments );
	}

	private string function index( event, rc, prc, args={} ) {
		args.context = args.context ?: "";

		args.remoteUrl   = event.buildLink( linkTo="formcontrols.IconPicker.ajaxGetIcons", querystring="q=%QUERY&context=#args.context#" );
		args.prefetchUrl = event.buildLink( linkTo="formcontrols.IconPicker.ajaxGetIcons", querystring="context=#args.context#" );

		return renderView( view="formcontrols/iconPicker/index", args=args );
	}

	public void function ajaxGetIcons( event, rc, prc ) {
		var query = rc.q       ?: "";
		var context = rc.context ?: "";
		var data    = [];

		if ( !isEmptyString( context ) ) {
			context &= ".";
		}

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
			var iconClass = translateResource( uri="formControls.iconPicker:#icon#.#context#iconClass", defaultValue=translateResource( uri="formControls.iconPicker:#icon#.iconClass", defaultValue="" ) );

			ArrayAppend( data, {
				  text      = translateResource( uri="formControls.iconPicker:#icon#.#context#label", defaultValue=translateResource( uri="formControls.iconPicker:#icon#.label", defaultValue="" ) )
				, iconClass = iconClass
				, value     = iconClass
			} );
		}

		event.renderData( type="json", data=data );
	}

}