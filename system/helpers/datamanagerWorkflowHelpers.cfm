<cfscript>
	function _commonDatamanagerWorkflowHelperProxy( required string func ) {
		var wfService = getSingleton( "datamanagerWorkflowService" );
		var event     = getController().getRequestContext();
		var prc       = event.getCollection( private=true );

		arguments.objectName = arguments.objectName ?: ( prc.objectName ?: "" );
		arguments.recordId   = arguments.recordId   ?: ( prc.recordId   ?: "" );

		if ( Len( arguments.objectName ) && Len( arguments.recordId ) ) {
			if ( event.isDataManagerRequest() && !StructKeyExists( arguments, "wfInstance" ) ) {
				if ( arguments.objectName == ( prc.objectName ?: "" ) && arguments.recordId == ( prc.recordId ?: ""  ) ) {
					arguments.wfInstance = prc.datamanagerWfInstance = prc.datamanagerWfInstance ?: wfService.getInstance( argumentCollection=arguments );
				}
			}

			if ( arguments.func == "getInstance" ) {
				return arguments.wfInstance;
			}

			if ( event.isDataManagerRequest() && !StructKeyExists( arguments, "wfInstance" ) ) {
				if ( arguments.objectName == ( prc.objectName ?: "" ) && arguments.recordId == ( prc.recordId ?: ""  ) ) {
					arguments.wfInstance = prc.datamanagerWfInstance = prc.datamanagerWfInstance ?: wfService.getInstance( argumentCollection=arguments );
				}
			}

			return wfService[ arguments.func ]( argumentCollection=arguments );
		}

		throw( type="datamanager.workflow.missing.objectname.or.recordid", message="A call to the helper [#arguments.func#] was made without supplying an objectName or recordId argument. This is only possible in the context of a datamanager request to an object record. In other instances, you must manually pass in these arguments." );
	}

	function getDatamanagerWorkflowInstance() {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="getInstance" );
	}

	function getDatamanagerWorkflowStepStatus( required string stepId ) {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="getStepStatus" );
	}
	function isDatamanagerWorkflowStepActive( required string stepId ) {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="isStepActive" );
	}
	function isDatamanagerWorkflowStepPending( required string stepId ) {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="isStepPending" );
	}
	function isDatamanagerWorkflowStepComplete( required string stepId ) {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="isStepComplete" );
	}
	function isDatamanagerWorkflowStepSkipped( required string stepId ) {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="isStepSkipped" );
	}
	function isDatamanagerWorkflowStepCompletedOrSkipped( required string stepId ) {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="isStepCompletedOrSkipped" );
	}
	function getDatamanagerWorkflowActiveSteps() {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="getActiveSteps" );
	}
	function getDatamanagerWorkflowStepStatuses() {
		return _commonDatamanagerWorkflowHelperProxy( argumentCollection=arguments, func="getStepStatuses" );
	}
</cfscript>