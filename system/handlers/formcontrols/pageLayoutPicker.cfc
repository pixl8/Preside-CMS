component output=false {

	property name="pageTypesService" inject="pageTypesService";

	public string function index( event, rc, prc, args={} ) output=false {
		var pageType = args.savedData.page_type ?: ( rc.page_type ?: "" );

		if ( !pageTypesService.pageTypeExists( pageType ) ) {
			return "**page type not found**";
		}

		pageType = pageTypesService.getPageType( pageType );
		var rawlayouts = pageType.listLayouts();
		if ( rawLayouts.len() <= 1 ) {
			return "";
		}

		args.layouts = [];

		for( var layout in rawlayouts ) {
			var specificLabelUri = "page-types.#pageType.getId()#:layout.#layout#";
			var defaultLabelUri  = "cms:page-layouts.default.#layout#";

			args.layouts.append( {
				  value = layout
				, label = translateResource( uri=specificLabelUri, defaultValue=translateResource( uri=defaultLabelUri, defaultValue=layout ) )
			} );
		}

		args.layouts.sort( function( valueA, valueB ){
			return valueA.label == valueB.label ? 0 : ( valueA.label > valueB.label ? 1 : -1 );
		} );


		return renderView( view="formcontrols/pageLayoutPicker/index", args=args );
	}
}