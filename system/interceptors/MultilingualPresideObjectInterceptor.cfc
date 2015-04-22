component extends="coldbox.system.Interceptor" output=false {

	property name="multilingualPresideObjectService" inject="provider:multilingualPresideObjectService";

// PUBLIC
	public void function configure() output=false {}

	public void function postReadPresideObjects( event, interceptData ) {
		multilingualPresideObjectService.addTranslationObjectsForMultilingualEnabledObjects(
			objects = ( interceptData.objects ?: {} )
		);
	}

	public void function postParseSelectFields( event, interceptData ) {
		if ( event.getLanguage().len() ) {
			multilingualPresideObjectService.mixinTranslationSpecificSelectLogicToSelectDataCall(
				argumentCollection = interceptData
			);
		}
	}

	public void function postPrepareTableJoins( event, interceptData ) {
		var language = event.getLanguage();
		if ( language.len() ){
			multilingualPresideObjectService.addLanguageClauseToTranslationJoins(
				  argumentCollection = interceptData
				, language           = language
			);
		}
	}

	public void function onCreateSelectDataCacheKey( event, interceptData ) {
		var language = event.getLanguage();
		if ( language.len() ){
			interceptData.cacheKey = interceptData.cacheKey ?: "";
			interceptData.cacheKey &= "_" & language;
		}
	}

}