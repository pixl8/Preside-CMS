/**
 * @feature presideForms and siteTree
 */
component {

	property name="presideObjectService" inject="presideObjectService";
	property name="dataManagerService"   inject="dataManagerService";

	public string function index( event, rc, prc, args={} ) {
		var prefetchCacheBuster = dataManagerService.getPrefetchCachebusterForAjaxSelect( "page" );

		if ( Len( Trim( args.savedData.id ?: "" ) ) ) {
			var sourceObject = args.sourceObject ?: "";

			if ( presideObjectService.isManyToManyProperty( sourceObject, args.name ) ) {
				args.savedValue = presideObjectService.selectManyToManyData(
					  objectName   = sourceObject
					, propertyName = args.name
					, id           = args.savedData.id
					, selectFields = [ "#args.name#.id" ]
				);

				args.defaultValue = args.savedValue = ValueList( args.savedValue.id );
			}
		}

		var filterBy      = args.filterBy      ?: "";
		var filterByField = args.filterByField ?: filterBy;

		args.maxRows      = Val( args.maxRows ?: 200 );
		args.defaultValue = args.defaultValue ?: "";
		args.childPage    = args.childPage    ?: "";
		args.multiple     = args.multiple     ?: ( ( args.relationship ?: "" ) == "many-to-many" );
		args.prefetchUrl  = event.buildAdminLink( linkTo="sitetree.getPagesForAjaxPicker", querystring="childPage=#args.childPage#&values=#args.defaultValue#&prefetchCacheBuster=#args.childPage##Hash( args.defaultValue )##prefetchCacheBuster#&filterBy=#filterBy#&filterByField=#filterByField#maxRows=#args.maxRows#" );
		args.remoteUrl    = event.buildAdminLink( linkTo="sitetree.getPagesForAjaxPicker", querystring="childPage=#args.childPage#&q=%QUERY&filterBy=#filterBy#&filterByField=#filterByField#&maxRows=#args.maxRows#" );

		if ( !Len( Trim( args.placeholder ?: "" ) ) ) {
			args.placeholder = translateResource(
				  uri  = "cms:datamanager.search.data.placeholder"
				, data = [ translateResource( uri=presideObjectService.getResourceBundleUriRoot( "page" ) & "title", defaultValue=translateResource( "cms:datamanager.records" ) ) ]
			);
		}

		return renderView( view="formcontrols/sitetreePagePicker/index", args=args );
	}
}