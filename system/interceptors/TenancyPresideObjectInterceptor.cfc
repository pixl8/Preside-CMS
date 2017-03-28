component extends="coldbox.system.Interceptor" {

	property name="tenancyService" inject="delayedInjector:tenancyService";

// PUBLIC
	public void function configure() {}

	public void function postReadPresideObject( event, interceptData ) {
		tenancyService.get().injectObjectTenancyProperties(
			  objectMeta = interceptData.objectMeta ?: {}
			, objectName = ListLast( interceptData.objectMeta.name ?: "", "." )
		);
	}

	public void function prePrepareObjectFilter( event, interceptData ) {
		var filter = tenancyService.get().getTenancyFilter( interceptData.objectName ?: "" );
		if ( filter.count() ) {
			interceptData.extraFilters = interceptData.extraFilters ?: [];
			interceptData.extraFilters.append( filter );
		}
	}

	public void function onCreateSelectDataCacheKey( event, interceptData ) {
		var tenancyCacheKey = tenancyService.get().getTenancyCacheKey( interceptData.objectName ?: "" );
		if ( tenancyCacheKey.len() ) {
			interceptData.cacheKey = interceptData.cacheKey ?: "";
			interceptData.cacheKey &= tenancyCacheKey;
		}
	}

	public void function preInsertObjectData( event, interceptData ) {
		var tenancyData = tenancyService.get().getTenancyFieldsForInsertData( interceptData.objectName ?: "" );
		if ( tenancyData.count() ) {
			interceptData.data = interceptData.data ?: {};
			interceptData.data.append( tenancyData );
		}
	}
}