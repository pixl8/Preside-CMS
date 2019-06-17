component extends="coldbox.system.Interceptor" {

	property name="multilingualPresideObjectService" inject="delayedInjector:multilingualPresideObjectService";
	property name="featureService"                   inject="delayedInjector:featureService";
	property name="loginService"                     inject="delayedInjector:loginService";

// PUBLIC
	public void function configure() {}

	public void function postReadPresideObjects( event, interceptData ) {
		if ( featureService.isFeatureEnabled( "multilingual" ) ) {
			multilingualPresideObjectService.addTranslationObjectsForMultilingualEnabledObjects(
				objects = ( interceptData.objects ?: {} )
			);
		}
	}

	public void function postParseSelectFields( event, interceptData ) {
		if ( featureService.isFeatureEnabled( "multilingual" ) && event.getLanguage().len() ) {
			multilingualPresideObjectService.mixinTranslationSpecificSelectLogicToSelectDataCall(
				argumentCollection = interceptData
			);
		}
	}

	public void function postPrepareTableJoins( event, interceptData ) {
		if ( featureService.isFeatureEnabled( "multilingual" ) && StructKeyExists( interceptData, "tableJoins" ) && StructKeyExists( interceptData, "preparedFilter" ) ) {
			var language = event.getLanguage();
			if ( language.len() ){
				multilingualPresideObjectService.addLanguageClauseToTranslationJoins(
					  argumentCollection = interceptData
					, language           = language
				);
			}
		}
	}

	public void function postPrepareVersionSelect( event, interceptData ) {
		if ( featureService.isFeatureEnabled( "multilingual" ) ) {
			var language = event.getLanguage();
			if ( language.len() ){
				multilingualPresideObjectService.addVersioningClausesToTranslationJoins( selectDataArgs=interceptData );
			}
		}
	}

	public void function onCreateSelectDataCacheKey( event, interceptData ) {
		if ( featureService.isFeatureEnabled( "multilingual" ) ) {
			var language = event.getLanguage();
			if ( language.len() ){
				interceptData.cacheKey = interceptData.cacheKey ?: "";
				interceptData.cacheKey &= "_" & language;
				interceptData.cacheKey &= "_" & loginService.isLoggedIn();
			}
		}
	}

}