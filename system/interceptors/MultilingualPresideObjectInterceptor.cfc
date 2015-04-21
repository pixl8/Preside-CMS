component extends="coldbox.system.Interceptor" output=false {

	property name="multilingualPresideObjectService" inject="provider:multilingualPresideObjectService";

// PUBLIC
	public void function configure() output=false {}

	public void function postReadPresideObjects( event, interceptData ) {
		multilingualPresideObjectService.addTranslationObjectsForMultilingualEnabledObjects(
			objects = ( interceptData.objects ?: {} )
		);
	}
}