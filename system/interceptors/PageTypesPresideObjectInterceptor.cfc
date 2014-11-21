component extends="coldbox.system.Interceptor" output=false {

// PUBLIC
	public void function configure() output=false {}

	public void function postReadPresideObject( event, interceptData ) output=false {
		var objectMeta = interceptData.objectMeta ?: {};

		objectMeta.isPageType = objectMeta.isPageType ?: _isPageTypeObject( objectMeta );

		if ( objectMeta.isPageType ) {
			_injectPageTypeFields( objectMeta );

			objectMeta.labelField = objectMeta.labelField ?: "page.title";
		}
	}

// PRIVATE HELPERS
	private boolean function _isPageTypeObject( required struct objectMeta ) output=false {
		var objectPath = arguments.objectMeta.name ?: "";

		return ReFindNoCase( "\.page-types\.", objectPath );
	}

	private void function _injectPageTypeFields( required struct meta ) output=false {
		var defaultConfiguration = { relationship="many-to-one", relatedto="page", required=true, uniqueindexes="page", ondelete="cascade", onupdate="cascade", generator="none" };

		param name="arguments.meta.properties.page" default={};
		StructAppend( arguments.meta.properties.page, defaultConfiguration, false );

		if ( not arguments.meta.propertyNames.find( "page" ) ) {
			ArrayAppend( arguments.meta.propertyNames, "page" );
		}
	}
}