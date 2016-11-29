component {

	property name="presideObjectService" inject="presideObjectService";
	property name="dataManagerService"   inject="dataManagerService";

	public string function index( event, rc, prc, args={} ) {

		var relatedField       = args.relatedField  ?: "";
		var relatedFieldId     = "";
		var extraFiltersString = "";
		var extraFilters       = args.extraFilters  ?: [];
		var targetObject       = args.object        ?: "";
		var ajax               = args.ajax          ?: true;
		var savedFilters       = args.objectFilters ?: "";

		if( !isEmpty( relatedField ) ){
			var objectName     = rc.object          ?: "";
			var objectId       = rc.id              ?: "";
			var versionId      = rc.version         ?: 0;

			try {
				var objectDetail = presideObjectService.selectData(
					  objectName      = objectName
					, id              = objectId
					, specificVersion = versionId
					, selectFields    = [ relatedField ]
				);
				relatedFieldId = objectDetail[ relatedField ];
				extraFilters.append({
					  filter       = "#relatedField#=:#relatedField#"
					, filterParams = { "#relatedField#" = relatedFieldId }
				});
			} catch( e ) {}
		}

		if( arrayLen( extraFilters ) ){
			extraFilters       = urlEncodedFormat( serializeJSON( extraFilters ) );
			extraFiltersString = "&extraFilters=#extraFilters#";
		}

		if ( IsBoolean( ajax ) && ajax ) {
			if ( not StructKeyExists( args, "prefetchUrl" ) ) {
				var prefetchCacheBuster = dataManagerService.getPrefetchCachebusterForAjaxSelect( targetObject );

				args.prefetchUrl = event.buildAdminLink(
					  linkTo      = "datamanager.getObjectRecordsForAjaxSelectControl"
					, querystring = "maxRows=100&object=#targetObject#&prefetchCacheBuster=#prefetchCacheBuster#&savedFilters=#savedFilters##extraFiltersString#"
				);
			}
			args.remoteUrl = args.remoteUrl ?: event.buildAdminLink(
				  linkTo      = "datamanager.getObjectRecordsForAjaxSelectControl"
				, querystring = "object=#targetObject#&savedFilters=#savedFilters##extraFiltersString#&q=%QUERY"
			);
		} else {
			args.records = IsQuery( args.records ?: "" ) ? args.records : presideObjectService.selectData(
				  objectName   = targetObject
				, selectFields = [ "#targetObject#.id", "${labelfield} as label" ]
				, orderBy      = "label"
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