component extends="coldbox.system.Interceptor" {

	property name="presideObjectService"          inject="delayedInjector:presideObjectService";
	property name="presideFieldRuleGenerator"     inject="delayedInjector:presideFieldRuleGenerator";
	property name="configuredValidationProviders" inject="coldbox:setting:validationProviders";

// PUBLIC
	public void function configure() {}

	public void function afterInstanceCreation( event, interceptData ) {
		var mapping = arguments.interceptData.mapping ?: "";

		if ( !IsSimpleValue( mapping ) ) {
			if ( mapping.getName() == "ValidationEngine" ) {
				var validationEngine = arguments.interceptData.target ?: "";

				if ( IsArray( configuredValidationProviders ) ) {
					for ( var providerName in configuredValidationProviders ) {
						validationEngine.newProvider( getModel( dsl=providerName ) );
					}
				}

				for( var objName in presideObjectService.listObjects( includeGeneratedObjects=true ) ) {
					var obj = presideObjectService.getObject( objName );
					if ( not IsSimpleValue( obj ) ) {
						validationEngine.newProvider( obj );
					}

					var rules = presideFieldRuleGenerator.generateRulesFromPresideObject( objName );
					validationEngine.newRuleset( name="PresideObject.#objName#", rules=rules );
				}
			}
		}
	}

}
