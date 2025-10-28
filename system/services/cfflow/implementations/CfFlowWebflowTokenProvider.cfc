/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component implements="preside.system.modules.cfflow.models.substitution.IWorkflowArgSubstitutionProvider" {

	/**
	 * @webflowConfigurationService.inject webflowConfigurationService
	 *
	 */
	public any function init( required any webflowConfigurationService ) {
		_setWebflowConfigurationService( arguments.webflowConfigurationService );

		return;
	}

	public struct function getTokens( required array requiredTokens, required WorkflowInstance wfInstance ){
		var requiredTokensList = ArrayToList( requiredTokens );
		var tokens             = {};

		if ( !ReFindNoCase( "\$webflow\.", requiredTokensList ) ) {
			return tokens;
		}

		var instanceArgs         = wfInstance.getInstanceArgs();
		var webflowId            = ReReplace( wfInstance.getWorkflowId(), "^preside\.webflow\.", "" );
		var instanceRef          = instanceArgs.subreference ?: "";
		var webflowConfRegex     = "\$webflow\.config\.(.*)$";
		var webflowStepConfRegex = "\$webflow\.step\.(.*?)\.config\.(.*)$";

		if ( ReFindNoCase( webflowConfRegex, requiredTokensList ) ) {
			var webflowConfig = _getWebflowConfigurationService().getFlowConfig( webflowId, instanceRef );

			for( var token in requiredTokens ) {
				if ( ReFindNoCase( webflowConfRegex, token ) ) {
					var field = ReReplaceNoCase( token, webflowConfRegex, "\1" );

					if ( IsSimpleValue( webflowConfig[ field ] ?: "" ) ) {
						tokens[ token ] = webflowConfig[ field ] ?: "";
					}
				}
			}
		}

		if ( ReFindNoCase( webflowStepConfRegex, requiredTokensList ) ) {
			var stepConfigs = {};

			for( var token in requiredTokens ) {
				if ( ReFindNoCase( webflowStepConfRegex, token ) ) {
					var step  = ReReplaceNoCase( token, webflowStepConfRegex, "\1" );
					var field = ReReplaceNoCase( token, webflowStepConfRegex, "\2" );

					try {
						stepConfigs[ step ] = stepConfigs[ step ] ?: _getWebflowConfigurationService().getStepConfig( webflowId, step, instanceRef );
					} catch( any e ) {
						stepConfigs[ step ] = {};
					}

					if ( IsSimpleValue( stepConfigs[ step ][ field ] ?: "" ) ) {
						tokens[ token ] = stepConfigs[ step ][ field ] ?: "";
					}
				}
			}
		}
		return tokens;
	}

// GETTERS AND SETTERS
	private any function _getWebflowConfigurationService() {
	    return _webflowConfigurationService;
	}
	private void function _setWebflowConfigurationService( required any webflowConfigurationService ) {
	    _webflowConfigurationService = arguments.webflowConfigurationService;
	}
}