/**
 * @feature presideForms
 */
component {

	property name="presideObjectService" inject="presideObjectService";
	property name="labelRendererService" inject="LabelRendererService";
	property name="dataManagerService"   inject="dataManagerService";

	public string function index( event, rc, prc, args={} ) {

		var targetObject     = args.object        ?: "";
		var targetIdField    = args.targetIdField ?:presideObjectService.getIdField( targetObject );
		var ajax             = args.ajax          ?: true;
		var savedFilters     = args.objectFilters ?: "";
		var orderBy          = args.orderBy       ?: datamanagerService.getDefaultSortOrderForObjectPicker( targetObject );
		var filterBy         = args.filterBy      ?: "";
		var filterByField    = args.filterByField ?: filterBy;
		var savedData        = args.savedData     ?: {};
		var bypassTenants    = args.bypassTenants ?: "";
		var labelRenderer    = args.labelRenderer = args.labelRenderer ?: presideObjectService.getObjectAttribute( targetObject, "labelRenderer" );
		var labelFields      = labelRendererService.getSelectFieldsForLabel( labelRenderer );
		var useCache         = IsTrue( args.useCache ?: "" );

		args.defaultValue    = _removeInvalidValues( objectName=targetObject, values=args.defaultValue, bypassTenants=bypassTenants );

		if ( IsBoolean( ajax ) && ajax ) {
			if ( not StructKeyExists( args, "prefetchUrl" ) ) {
				var prefetchCacheBuster = dataManagerService.getPrefetchCachebusterForAjaxSelect( targetObject, labelRenderer );
				args.prefetchUrl = event.buildAdminLink(
					  linkTo      = "datamanager.getObjectRecordsForAjaxSelectControl"
					, querystring = "maxRows=100&targetIdField=#targetIdField#&object=#targetObject#&prefetchCacheBuster=#prefetchCacheBuster#&savedFilters=#savedFilters#&orderBy=#orderBy#&labelRenderer=#labelRenderer#&filterBy=#filterBy#&filterByField=#filterByField#&bypassTenants=#bypassTenants#&useCache=#useCache#&defaultValue=#args.defaultValue#"
				);
			}
			args.remoteUrl = args.remoteUrl ?: event.buildAdminLink(
				  linkTo      = "datamanager.getObjectRecordsForAjaxSelectControl"
				, querystring = "object=#targetObject#&targetIdField=#targetIdField#&savedFilters=#savedFilters#&orderBy=#orderBy#&labelRenderer=#labelRenderer#&filterBy=#filterBy#&filterByField=#filterByField#&bypassTenants=#bypassTenants#&useCache=#useCache#&defaultValue=#args.defaultValue#&q=%QUERY"
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

			var selectArgs = {
				  objectName    = targetObject
				, selectFields  = labelFields.append( "#targetObject#.#targetIdField# as id" )
				, orderBy       = orderBy
				, filter        = filter
				, savedFilters  = ListToArray( savedFilters )
				, bypassTenants = ListToArray( bypassTenants )
				, useCache      = useCache
				, defaultValue  = args.defaultValue
			};

			announceInterception( "preObjectPickerSelectData", selectArgs );

			args.records = IsQuery( args.records ?: "" ) ? args.records : presideObjectService.selectData(
				argumentCollection = selectArgs
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

	private string function _removeInvalidValues( required string objectName, required string values, string bypassTenants="" ) {
		if ( !len( arguments.values ?: "" ) ) {
			return "";
		}

		var initialValues = listToArray( arguments.values );
		var validValues   = presideObjectService.selectData(
			  objectName    = arguments.objectName
			, filter        = { id=initialValues }
			, selectFields  = [ "id" ]
			, bypassTenants = ListToArray( arguments.bypassTenants )
		).columnData( "id" );

		var cleanedValues = initialValues.filter( function( value ){
			return validValues.find( value );
		} );

		return cleanedValues.toList();
	}
}
