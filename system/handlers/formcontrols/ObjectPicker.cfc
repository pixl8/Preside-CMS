component {

	property name="presideObjectService" inject="presideObjectService";
	property name="labelRendererService" inject="LabelRendererService";
	property name="dataManagerService"   inject="dataManagerService";

	public string function index( event, rc, prc, args={} ) {

		var targetObject  = args.object        ?: "";
		var targetIdField = presideObjectService.getIdField( targetObject );
		var ajax          = args.ajax          ?: true;
		var savedFilters  = args.objectFilters ?: "";
		var orderBy       = args.orderBy       ?: "label";
		var filterBy      = args.filterBy      ?: "";
		var filterByField = args.filterByField ?: filterBy;
		var savedData     = args.savedData     ?: {};
		var labelRenderer = args.labelRenderer = args.labelRenderer ?: presideObjectService.getObjectAttribute( targetObject, "labelRenderer" );
		var labelFields   = labelRendererService.getSelectFieldsForLabel( labelRenderer );

		if ( IsBoolean( ajax ) && ajax ) {
			if ( not StructKeyExists( args, "prefetchUrl" ) ) {
				var prefetchCacheBuster = dataManagerService.getPrefetchCachebusterForAjaxSelect( targetObject, labelRenderer );
				args.prefetchUrl = event.buildAdminLink(
					  linkTo      = "datamanager.getObjectRecordsForAjaxSelectControl"
					, querystring = "maxRows=100&object=#targetObject#&prefetchCacheBuster=#prefetchCacheBuster#&savedFilters=#savedFilters#&orderBy=#orderBy#&labelRenderer=#labelRenderer#&filterBy=#filterBy#&filterByField=#filterByField#"
				);
			}
			args.remoteUrl = args.remoteUrl ?: event.buildAdminLink(
				  linkTo      = "datamanager.getObjectRecordsForAjaxSelectControl"
				, querystring = "object=#targetObject#&savedFilters=#savedFilters#&orderBy=#orderBy#&labelRenderer=#labelRenderer#&filterBy=#filterBy#&filterByField=#filterByField#&q=%QUERY"
			);
		} else {
			var filter = {};
			var i      = 0;
			filterBy      = listToArray( filterBy );
			filterByField = listToArray( filterByField );

			for( var key in filterBy ) {
				i++;
				if ( structKeyExists( savedData, key ) ) {
					filter[ "#targetObject#.#filterByField[ i ]#" ] = savedData[ key ];
				}
			}

			args.records = IsQuery( args.records ?: "" ) ? args.records : presideObjectService.selectData(
				  objectName   = targetObject
				, selectFields = labelFields.append( "#targetObject#.#targetIdField# as id" )
				, orderBy      = orderBy
				, filter       = filter
				, savedFilters = ListToArray( savedFilters )
			);
		}

		if ( !Len( Trim( args.placeholder ?: "" ) ) ) {
			args.placeholder = translateResource(
				  uri  = "cms:datamanager.search.data.placeholder"
				, data = [ translateResource( uri=presideObjectService.getResourceBundleUriRoot( targetObject ) & "title", defaultValue=translateResource( "cms:datamanager.records" ) ) ]
			);
		}

		return renderView( view="formcontrols/objectPicker/index", args=args );
	}
}
