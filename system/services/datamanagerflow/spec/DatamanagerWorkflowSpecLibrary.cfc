/**
 * @feature        datamanagerWorkflow
 * @presideService true
 * @singleton      true
 */
component {

	variables._flows = {};

	property name="yamlParser"        inject="yamlParser@cfflow";
	property name="workflowValidator" inject="datamanagerWorkflowValidator";

	function init() {
		return this;
	}

	function postInit() {
		_setupValidator();
	}

	function registerWorkflow( required any spec ) {
		var converted = _convertSpec( arguments.spec );

		_validateWorkflow( converted );

		if ( Len( Trim( converted.workflow.feature ?: "" ) ) && !$isFeatureEnabled( converted.workflow.feature ) ) {
			return;
		}

		_flows[ converted.workflow.id ] = converted.workflow;

		return _flows[ converted.workflow.id ];
	}

	function getWorkflow( required string workflowId ) {
		return _flows[ arguments.workflowId ] ?: {};
	}

	function getWorkflowStep( required string workflowId, required string stepId ) {
		var flow = getWorkflow( arguments.workflowId );
		var steps = flow.steps ?: [];

		for( var step in steps ) {
			if ( step.id == arguments.stepId ) {
				return step;
			}
		}

		return {};
	}

	function getWorkflowStepAction( required string workflowId, required string stepId, required string actionId ) {
		var step    = getWorkflowStep( arguments.workflowId, arguments.stepId );
		var actions = step.actions ?: [];

		for( var action in actions ) {
			if ( action.id == arguments.actionId ) {
				return action;
			}
		}

		return {};
	}

	function getAutoActions( required string workflowId, required string stepId, required string actionTrigger ) {
		var step        = getWorkflowStep( arguments.workflowId, arguments.stepId );
		var stepActions = step.actions ?: [];
		var autoActions = [];

		for( var action in stepActions ) {
			if ( action.type == "auto" && ( ArrayFind( action.triggers, "*" ) || ArrayFindNoCase( action.triggers, arguments.actionTrigger ) ) ) {
				ArrayAppend( autoActions, action );
			}
		}

		return autoActions;
	}

// PRIVATE HELPERS
	private function _convertSpec( spec ) {
		// given a struct
		if ( IsStruct( arguments.spec ) && !IsObject( arguments.spec ) ) {
			return arguments.spec;

		// given a string
		} else if ( IsSimpleValue( arguments.spec ) ) {
			// if a file path, presume a YAML file with workflow definition
			if ( FileExists( arguments.spec ) ) {
				return yamlParser.deserialize( FileRead( arguments.spec ) );

			// otherwise, presume YAML string
			} else {
				return yamlParser.deserialize( arguments.spec );
			}
		}
	}

	private function _validateWorkflow( spec ) {
		var result = workflowValidator.validate( SerializeJson( spec ) );

		if ( !result.valid ) {
			var message = result.message ?: "Your datamanager workflow definition is invalid. Please see error detail for details.";
			var type    = "preside.datamanager.workflow.invalid.spec";
			var detail  = "Validation details: " & SerializeJson( result.error ?: {} );

			throw( message, type, detail );
		}
	}

	private void function _setupValidator() {
		if ( !Len( workflowValidator.getSchemaFilePath() ) ) {
			var schemaPath = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "schema/datamanager.workflow.schema.json";
	    	var rootUri    = "file://#GetDirectoryFromPath( schemaPath )#";

			workflowValidator.setSchemaFilePath( schemaPath );
			workflowValidator.setSchemaBaseUri( rootUri );
		}
	}

	private any function _weakRef( target ) {
		return CreateObject( "java", "java.lang.ref.WeakReference" ).init( arguments.target );
	}
}