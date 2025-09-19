component extends="coldbox.system.Interceptor" {

	property name="cfflow"                      inject="delayedInjector:cfflow@cfflow";
	property name="storageClass"                inject="delayedInjector:CfFlowPresideStorage";
	property name="dmStorageClass"              inject="delayedInjector:CfFlowDatamanagerFlowStorage";
	property name="scheduler"                   inject="delayedInjector:CfFlowPresideScheduler";
	property name="coldboxProvider"             inject="delayedInjector:CfFlowColdboxProvider";
	property name="presideLoggedInCondition"    inject="delayedInjector:CfFlowPresideLoggedInCondition";
	property name="presideTokenProvider"        inject="delayedInjector:CfFlowPresideTokenProvider";
	property name="webflowTokenProvider"        inject="delayedInjector:CfFlowWebflowTokenProvider";
	property name="webflowService"              inject="delayedInjector:webflowService";
	property name="webflowSpecLibrary"          inject="delayedInjector:webflowSpecLibrary";
	property name="webflowConfigurationService" inject="delayedInjector:webflowConfigurationService";
	property name="webflowDirectories"          inject="presidecms:directories:workflow";
	property name="siteService"                 inject="delayedInjector:siteService";
	property name="presideObjectService"        inject="delayedInjector:presideObjectService";

// PUBLIC
	public void function configure() {}

	public void function onApplicationStart( event, interceptData ) {
		if ( !isFeatureEnabled( "webflow" ) ) {
			return;
		}

		_registerTokenProviders();
		_registerWorkflowClasses();
		_registerWorkflowFunctionsAndConditions()
		_registerWebflowStepsAndFlows();
		_initializeWebflowConfigurationSingletons( event );

		webflowService.ensureWebflowConfigMatchWithDefined();
	}

	public void function postInsertObjectData( event, interceptData ) {
		if ( !isFeatureEnabled( "webflow" ) ) {
			return;
		}

		var objectName = interceptData.objectName ?: "";
		var recordId   = interceptData.newId      ?: "";

		if ( objectName == "site" && Len( Trim( recordId )) ) {
			_initializeWebflowConfigurationSingletons( event, recordId );
		}
	}

// HELPERS
	private void function _registerTokenProviders() {
		var flow = cfflow.get();

		flow.registerTokenProvider( presideTokenProvider.get() );
		flow.registerTokenProvider( webflowTokenProvider.get() );
	}

	private void function _registerWorkflowClasses() {
		var flow = cfflow.get();

		flow.registerStorageClass(
			  className      = "preside.standard.db"
			, implementation = storageClass.get()
		);
		flow.registerStorageClass(
			  className      = "preside.datamanagerflow.db"
			, implementation = dmStorageClass.get()
		);
		flow.registerScheduler(
			  className      = "preside.scheduler"
			, implementation = scheduler.get()
		);
		flow.registerWorkflowClass(
			  className          = "preside.standard.flow"
			, storageClass       = "preside.standard.db"
			, scheduler          = "preside.scheduler"
		);
		flow.registerWorkflowClass(
			  className          = "preside.datamanagerflow.flow"
			, storageClass       = "preside.datamanagerflow.db"
			, scheduler          = "preside.scheduler"
		);
	}

	private void function _registerWorkflowFunctionsAndConditions( event, interceptData ) {
		var flow = cfflow.get();

		flow.registerFunction(
			  id             = "coldbox.handler"
			, implementation = coldboxProvider.get()
		);
		flow.registerCondition(
			  id             = "coldbox.handler"
			, implementation = coldboxProvider.get()
		);
		flow.registerCondition(
			  id             = "preside.IsLoggedIn"
			, implementation = presideLoggedInCondition.get()
		);
	}

	private void function _registerWebflowStepsAndFlows() {
		var directories = webflowDirectories;
		var flowService = webflowService.get();

		for( var dir in directories ) {
			flowService.loadStepDirectory( dir & "/webflowSteps");
		}
		for( var dir in directories ) {
			flowService.loadSubflowDirectory( dir & "/webflowSubflows");
		}
		for( var dir in directories ) {
			flowService.loadFlowDirectory( dir & "/webflows");
		}
	}

	private void function _initializeWebflowConfigurationSingletons( event, siteId="" ) {
		var flows          = webflowSpecLibrary.getAllWebflows();
		var steps          = webflowSpecLibrary.getAllSteps();
		var isSiteTenanted = ListFindNoCase( presideObjectService.getObjectAttribute( "webflow_configuration", "tenant" ), "site" );

		if ( isSiteTenanted ) {
			var sites = siteService.listSites();
			var currentSite = StructCopy( event.getSite() );

			for( var site in sites ) {
				if ( !Len( Trim( arguments.siteId ) ) || arguments.siteId == site.id ) {
					event.setSite( site );
					_initializeWebflowConfigurationSingletonsForSite( flows, steps );
				}
			}

			event.setSite( currentSite );
		} else if ( !Len( Trim( arguments.siteId ) ) ) {
			_initializeWebflowConfigurationSingletonsForSite( flows, steps );
		}
	}

	private void function _initializeWebflowConfigurationSingletonsForSite( flows, steps ) {
		for( var stepId in steps ) {
			webflowConfigurationService.initializeStep( stepId );
		}

		for( var flowId in flows ) {
			if ( webflowSpecLibrary.getWebflow( flowId ).getSingleton() ) {
				webflowConfigurationService.initializeSingleton( flowId );
				webflowConfigurationService.ensureSingletonAdminFlagUpdated( flowId );
			}
		}
	}


}