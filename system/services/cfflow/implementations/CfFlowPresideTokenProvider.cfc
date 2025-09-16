/**
 * @feature        cfflow
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.modules.cfflow.models.substitution.IWorkflowArgSubstitutionProvider" {

	public any function init() {
		return;
	}

	public struct function getTokens( required array requiredTokens, required WorkflowInstance wfInstance ){
		var requiredTokensList = ArrayToList( requiredTokens );
		var tokens = {};

		if ( ReFindNoCase( "\$coldbox\.setting\.", requiredTokensList ) ) {
			StructAppend( tokens, _getColdboxSettingTokens( argumentCollection=arguments ) );
		}

		if ( ReFindNoCase( "\$preside\.setting\.", requiredTokensList ) ) {
			StructAppend( tokens, _getPresideSettingTokens( argumentCollection=arguments ) );
		}

		if ( ReFindNoCase( "\$preside\.webuser\.", requiredTokensList ) ) {
			StructAppend( tokens, _getPresideWebUserTokens( argumentCollection=arguments ) );
		}

		return tokens;
	}

// PRIVATE HELPERS
	private struct function _getColdboxSettingTokens( requiredTokens ) {
		var cb           = $getColdbox();
		var regexPattern = "^\$coldbox\.setting\.(.*)$";
		var tokens       = {};

		for( var token in  requiredTokens ) {
			if ( ReFindNoCase( regexPattern, token ) ) {
				var settingName  = ReReplaceNoCase( token, regexPattern, "\1" );
				var settingValue = cb.getSetting( name=settingName, defaultValue="" );

				if ( IsSimpleValue( settingValue ) ) {
					tokens[ token ] = settingValue;
				} else {
					tokens[ token ] = "";
				}
			}
		}

		return tokens;
	}

	private struct function _getPresideSettingTokens( requiredTokens ) {
		var regexPattern = "^\$preside\.setting\.(.*?)\.(.*)$";
		var tokens       = {};

		for( var token in  requiredTokens ) {
			if ( ReFindNoCase( regexPattern, token ) ) {
				var settingCategory  = ReReplaceNoCase( token, regexPattern, "\1" );
				var settingName  = ReReplaceNoCase( token, regexPattern, "\2" );
				var settingValue = $getPresideSetting( category=settingCategory, setting=settingName, default="" );

				if ( IsSimpleValue( settingValue ) ) {
					tokens[ token ] = settingValue;
				} else {
					tokens[ token ] = "";
				}
			}
		}

		return tokens;
	}

	private struct function _getPresideWebUserTokens( requiredTokens ) {
		var regexPattern = "^\$preside\.webuser\.(.*?)$";
		var tokens       = {};
		var userData     = $getWebsiteLoggedInUserDetails();

		for( var token in  requiredTokens ) {
			if ( ReFindNoCase( regexPattern, token ) ) {
				var userField = ReReplaceNoCase( token, regexPattern, "\1" );
				var value     = userData[ userField ] ?: "";

				if ( IsSimpleValue( value ) ) {
					tokens[ token ] = value;
				} else {
					tokens[ token ] = "";
				}
			}
		}

		return tokens;
	}


}