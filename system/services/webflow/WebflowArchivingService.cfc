/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @webflowLibrary.inject              webflowSpecLibrary
	 * @webflowConfigurationService.inject webflowConfigurationService
	 * @cfFlowPresideStorage.inject        cfFlowPresideStorage
	 */
	public any function init(
		  required any webflowLibrary
		, required any webflowConfigurationService
		, required any cfFlowPresideStorage
	) {
		_setWebflowLibrary( arguments.webflowLibrary );
		_setWebflowConfigurationService( arguments.webflowConfigurationService );
		_setCfFlowPresideStorage( arguments.cfFlowPresideStorage );

		return this;
	}

// PUBLIC API METHODS
	public boolean function archiveExpiredWebflows( any logger ) {
		var flows        = _getWebflowLibrary().getAllWebflows();
		var confService  = _getWebflowConfigurationService();
		var storage      = _getCfFlowPresideStorage();
		var instanceDao  = $getPresideObject( "cfflow_workflow_instance" );
		var expiredCount = 0;
		var oneDay       = 60*24;

		for( var flowId in flows ) {
			var conf    = confService.getFlowConfig( flowId );
			var timeout = Val( conf.timeout_in_minutes ?: "" );

			if ( !timeout ) {
				logger?.debug( "Skipping webflow instances for webflow: " & flowId & ". Webflow does not have expiry." );
				continue;
			}

			logger?.info( "Checking expired webflow instances for webflow: " & flowId );

			var cfFlowId   = "preside.webflow.#flowId#";
			var cutOffDate = DateAdd( "n", 0-( timeout+oneDay ), Now() );
			var instances  = instanceDao.selectData(
				  filter       = "workflow_id = :workflow_id and datemodified < :datemodified"
				, filterParams = { workflow_id=cfFlowId, datemodified=cutOffDate }
				, selectFields = [ "owner", "reference", "sub_reference", "sub_sub_reference", "completed" ]
			);

			if ( !instances.recordCount ) {
				logger?.info( "No expired instances found for: " & flowId );
			} else {
				logger?.info( "[#NumberFormat( instances.recordCount )#] expired instances found for: " & flowId & ". Archiving..." );
			}

			for( var instance in instances ) {
				storage.archiveInstance(
					  workflowId    = cfFlowId
					, archiveReason = instance.completed ? "complete" : "timedout"
					, instanceArgs  = {
						  owner           = instance.owner
						, reference       = instance.reference
						, subreference    = instance.sub_reference
						, subSubReference = instance.sub_sub_reference
					  }
				);
			}

			if ( instances.recordCount ) {
				logger?.info( "[#NumberFormat( instances.recordCount )#] instances archived for flow: " & flowId & "." );
			}
		}

		logger?.info( "Finished archiving webflow instances." );

		return true;
	}


// PRIVATE HELPERS

// GETTERS AND SETTERS
	private any function _getWebflowLibrary() {
	    return _webflowLibrary;
	}
	private void function _setWebflowLibrary( required any webflowLibrary ) {
	    _webflowLibrary = arguments.webflowLibrary;
	}

	private any function _getWebflowConfigurationService() {
	    return _webflowConfigurationService;
	}
	private void function _setWebflowConfigurationService( required any webflowConfigurationService ) {
	    _webflowConfigurationService = arguments.webflowConfigurationService;
	}

	private any function _getCfFlowPresideStorage() {
	    return _cfFlowPresideStorage;
	}
	private void function _setCfFlowPresideStorage( required any cfFlowPresideStorage ) {
	    _cfFlowPresideStorage = arguments.cfFlowPresideStorage;
	}
}