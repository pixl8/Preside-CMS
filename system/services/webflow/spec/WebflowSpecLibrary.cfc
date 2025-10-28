/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

	variables._flows = {};
	variables._steps = {};
	variables._subFlows = {};

// CONSTRUCTOR
	/**
	 * @yamlParser.inject       yamlParser@cfflow
	 * @webflowValidator.inject webflowValidator
	 * @stepValidator.inject    webflowStepValidator
	 * @subflowValidator.inject webflowSubflowValidator
	 *
	 */
	public any function init(
		  required any yamlParser
		, required any webflowValidator
		, required any stepValidator
		, required any subflowValidator
	) {
		_setYamlParser( arguments.yamlParser );
		_setWebflowValidator( arguments.webflowValidator );
		_setStepValidator( arguments.stepValidator );
		_setSubflowValidator( arguments.subflowValidator );

		return this;
	}

// PUBLIC API METHODS
	public any function registerWebflow( required any spec ) {
		var converted = _convertSpec( arguments.spec );

		_validateWebflow( converted );
		if ( Len( Trim( converted.webflow.feature ?: "" ) ) && !$isFeatureEnabled( converted.webflow.feature ) ) {
			return;
		}

		_flows[ converted.webflow.id ] = {
			  raw  = converted
			, full = _weakRef( _readWebflow( converted ) )
		};

		return _flows[ converted.webflow.id ].full.get();
	}

	public struct function getAllWebflows() {
		return variables._flows;
	}

	public struct function getAllSteps() {
		return variables._steps;
	}

	public struct function getAllSubflows() {
		return variables._steps;
	}

	public any function getWebflow( required string id ) {
		var flow = variables._flows[ arguments.id ] ?: throw(
			  "The webflow with ID, [#arguments.id#], could not be found."
			, "preside.webflow.not.found"
		);

		if ( !StructKeyExists( flow, "full" ) || IsNull( flow.full ) || IsNull( flow.full.get() ) ) {
			flow.full = _weakRef( _readWebflow( flow.raw ) );
		}

		return flow.full.get();
	}

	public any function getWebflowStep( required string webflowId, required string stepId ) {
		var steps = getWebflow( arguments.webflowId ).getSteps();

		for( var step in steps ) {
			if ( step.getId() == arguments.stepId ) {
				return step;
			}
		}

		throw(
			  "The webflow step with ID, [#arguments.stepId#], could not be found in webflow [#arguments.webflowId#]."
			, "preside.webflow.step.not.found"
		);
	}

	public any function registerStep( required any spec ) {
		var converted = _convertSpec( arguments.spec );

		_validateStep( converted );
		if ( Len( Trim( converted.feature ?: "" ) ) && !$isFeatureEnabled( converted.feature ) ) {
			return;
		}

		_steps[ converted.id ] = {
			  raw  = converted
			, full = _weakRef( _readStep( converted ) )
		};

		return _steps[ converted.id ].full.get();
	}

	public any function getStep( required string id ) {
		var step = variables._steps[ arguments.id ] ?: throw(
			  "The webflow step with ID, [#arguments.id#], could not be found."
			, "preside.webflow.step.not.found"
		);

		if ( !StructKeyExists( step, "full" ) || IsNull( step.full ) || IsNull( step.full.get() ) ) {
			step.full = _weakRef( _readStep( step.raw ) );
		}

		return step.full.get();
	}

	public any function registerSubflow( required any spec ) {
		var converted = _convertSpec( arguments.spec );

		_validateSubflow( converted );

		if ( Len( Trim( converted.feature ?: "" ) ) && !$isFeatureEnabled( converted.feature ) ) {
			return;
		}

		_subflows[ converted.id ] = {
			  raw  = converted
			, full = _weakRef( _readSubflow( converted ) )
		};

		return _subflows[ converted.id ].full.get();
	}

	public any function getSubflow( required string id ) {
		var flow = variables._subflows[ arguments.id ] ?: throw(
			  "The subflow with ID, [#arguments.id#], could not be found."
			, "preside.webflow.subflow.not.found"
		);

		if ( !StructKeyExists( flow, "full" ) || IsNull( flow.full ) || IsNull( flow.full.get() ) ) {
			flow.full = _weakRef( _readSubflow( flow.raw ) );
		}

		return flow.full.get();
	}


// PRIVATE HELPERS
	private struct function _convertSpec( required any spec ) {
		// given a struct
		if ( IsStruct( arguments.spec ) && !IsObject( arguments.spec ) ) {
			return arguments.spec;

		// given a string
		} else if ( IsSimpleValue( arguments.spec ) ) {
			// if a file path, presume a YAML file with workflow definition
			if ( FileExists( arguments.spec ) ) {
				return _getYamlParser().deserialize( FileRead( arguments.spec ) );

			// otherwise, presume YAML string
			} else {
				return _getYamlParser().deserialize( arguments.spec );
			}
		}
	}

	private any function _readWebflow( required any spec ) {
		return new Webflow(
			  id                = spec.webflow.id    ?: ""
			, meta              = spec.webflow.meta  ?: {}
			, init              = spec.webflow.init  ?: {}
			, steps             = _readRawSteps( spec.webflow.steps ?: [] )
			, singleton         = IsBoolean( spec.webflow.singleton      ?: "" ) && spec.webflow.singleton
			, adminFlow         = IsBoolean( spec.webflow.adminFlow      ?: "" ) && spec.webflow.adminFlow
			, hideFromWidget    = IsBoolean( spec.webflow.hideFromWidget ?: "" ) && spec.webflow.hideFromWidget
			, cfflowId          = "preside.webflow." & ( spec.webflow.id ?: "" )
			, layout            = spec.webflow.layout ?: {}
			, preCancelHandler  = spec.webflow.preCancelHandler ?: {}
			, postCancelHandler = spec.webflow.postCancelHandler ?: {}
			, instRefConfig     = spec.webflow.instRefConfig ?: {}
		);
	}

	private any function _readStep( required any spec ) {
		var next = spec.next ?: [];
		if ( !IsArray( next ) ) {
			next = [ next ];
		}
		var prev = spec.prev ?: [];
		if ( !IsArray( prev ) ) {
			prev = [ prev ];
		}

		var step = new WebflowStep(
			  id                  = spec.id               ?: ""
			, stepRef             = spec.stepRef          ?: ""
			, subflowRef          = spec.subflowRef       ?: ""
			, parentSubflowRef    = spec.parentSubflowRef ?: ""
			, configform          = spec.configform       ?: ""
			, preActions          = spec.preActions       ?: []
			, postActions         = spec.postActions      ?: []
			, display             = spec.display          ?: {}
			, submission          = spec.submission       ?: {}
			, condition           = spec.condition        ?: {}
			, config              = spec.config           ?: {}
			, next                = next
			, prev                = prev
			, finish              = IsBoolean( spec.finish ?: "" ) && spec.finish
			, start               = IsBoolean( spec.start  ?: "" ) && spec.start
			, canCancel           = IsBoolean( spec.canCancel  ?: "" ) && spec.canCancel
			, ignoreTimeout       = IsBoolean( spec.submission.ignoreTimeout  ?: "" ) && spec.submission.ignoreTimeout
			, subflowEntryPoint   = IsBoolean( spec.subflowEntryPoint ?: "" ) && spec.subflowEntryPoint
			, subflowExitPoint    = IsBoolean( spec.subflowExitPoint  ?: "" ) && spec.subflowExitPoint
			, subflowExitPointFor = spec.subflowExitPointFor ?: []
		);

		return step;
	}

	private any function _readSubflow( required any spec ) {
		return new WebflowSubflow(
			  id    = spec.id ?: ""
			, steps = _readRawSteps( spec.steps ?: [], spec.id ?: "" )
		);
	}

	private array function _readRawSteps( required array rawSteps, string subflow="" ) {
		var steps = [];
		var isFirst = true;
		for( var step in arguments.rawSteps ) {
			if ( Len( Trim( step.feature ?: "" ) ) && !$isFeatureEnabled( step.feature ) ) {
				continue;
			}
			if ( Len( Trim( step.$ref ?: "" ) ) ) {
				StructAppend( step, getStep( step.$ref ).getMemento(), false );
				step.stepRef = step.$ref;
				step.subflowRef = arguments.subflow;
				steps.append( _readStep( step ) );
			} else if ( Len( Trim( step.$subflowref ?: "" ) ) ) {
				var subflow = getSubflow( step.$subflowref );
				var subSteps = subflow.getSteps();
				for( var i=1; i<=substeps.len(); i++ ) {
					var subStep = substeps[ i ];
					var newstep = Duplicate( substep.getMemento() );

					StructAppend( newstep.config, step.config ?: {} );

					if ( Len( Trim( arguments.subflow ) ) ) {
						newStep.parentSubflowRef = arguments.subflow;
					}

					if ( i==1 || subStep.getSubflowEntryPoint() ) {
						newstep.prev = newstep.prev ?: [];
						newstep.prev.append( ( step.prev ?: [] ), true );
						newstep.preactions = newstep.preactions ?: [];
						newstep.preactions.append( ( step.preactions ?: [] ), true );

						if ( StructCount( step.condition ?: {} ) ) {
							if ( subStep.hasCondition() ) {
								newStep.condition = {
									  ref  = "bool.isTruthy"
									, args = { value="true" }
									, and  = [ StructCopy( step.condition ), StructCopy( subStep.getCondition() ) ]
								};
							} else {
								newStep.condition = StructCopy( step.condition );
							}
						}

						if ( isFirst || ( step.start ?: false ) ) {
							newStep.start = true;
						}
					}
					if ( i==substeps.len() || subStep.getSubflowExitPoint() ) {
						newStep.subflowExitPoint = true;
						newStep.subflowExitPointFor = newStep.subflowExitPointFor ?: [];
						newStep.subflowExitPointFor.append( subflow.getId() )
						newstep.next = newstep.next ?: [];
						newstep.next.append( ( step.next ?: [] ), true );
						newstep.postactions = newstep.postactions ?: [];
						newstep.postactions.append( ( step.postactions ?: [] ), true );
						if ( step.finish ?: false ) {
							newstep.finish = true;
						}

						if ( step.subflowExitPoint ?: false ) {
							newStep.subflowExitPointFor.append( arguments.subflow );
						}
					}

					steps.append( _readStep( newStep ) );
				}
			} else {
				step.subflowRef = arguments.subflow;
				steps.append( _readStep( step ) );
			}

			isFirst = false;
		}

		return steps;
	}

	private void function _validateWebflow( required struct spec ) {
		var result = _getWebflowValidator().validate( SerializeJson( spec ) );

		if ( !result.valid ) {
			var message = result.message ?: "Your webflow definition is invalid. Please see error detail for details.";
			var type    = "preside.webflow.invalid.spec";
			var detail  = "Validation details: " & SerializeJson( result.error ?: {} );

			throw( message, type, detail );
		}
	}

	private void function _validateStep( required struct spec ) {
		var result = _getStepValidator().validate( SerializeJson( spec ) );

		if ( !result.valid ) {
			var message = result.message ?: "Your webflow step definition is invalid. Please see error detail for details.";
			var type    = "preside.webflow.step.invalid.spec";
			var detail  = "Validation details: " & SerializeJson( result.error ?: {} );

			throw( message, type, detail );
		}
	}

	private void function _validateSubflow( required struct spec ) {
		var result = _getSubflowValidator().validate( SerializeJson( spec ) );

		if ( !result.valid ) {
			var message = result.message ?: "Your subflow definition is invalid. Please see error detail for details.";
			var type    = "preside.webflow.subflow.invalid.spec";
			var detail  = "Validation details: " & SerializeJson( result.error ?: {} );

			throw( message, type, detail );
		}
	}

	private any function _weakRef( target ) {
		return CreateObject( "java", "java.lang.ref.WeakReference" ).init( arguments.target );
	}


// GETTERS AND SETTERS
	private any function _getYamlParser() {
	    return _yamlParser;
	}
	private void function _setYamlParser( required any yamlParser ) {
	    _yamlParser = arguments.yamlParser;
	}

	private any function _getWebflowValidator() {
	    return _webflowValidator;
	}
	private void function _setWebflowValidator( required any webflowValidator ) {
	    _webflowValidator = arguments.webflowValidator;

	    var schemaPath = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "schema/webflow.schema.json";
	    var rootUri    = "file://#GetDirectoryFromPath( schemaPath )#";

	    _webflowValidator.setSchemaFilePath( schemaPath );
	    _webflowValidator.setSchemaBaseUri( rootUri );
	}

	private any function _getStepValidator() {
	    return _stepValidator;
	}
	private void function _setStepValidator( required any stepValidator ) {
	    _stepValidator = arguments.stepValidator;

	    var schemaPath = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "schema/webflow.step.schema.json";
	    var rootUri    = "file://#GetDirectoryFromPath( schemaPath )#";

	    _stepValidator.setSchemaFilePath( schemaPath );
	    _stepValidator.setSchemaBaseUri( rootUri );
	}

	private any function _getSubflowValidator() {
	    return _subflowValidator;
	}
	private void function _setSubflowValidator( required any subflowValidator ) {
	    _subflowValidator = arguments.subflowValidator;

	    var schemaPath = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "schema/webflow.subflow.schema.json";
	    var rootUri    = "file://#GetDirectoryFromPath( schemaPath )#";

	    _subflowValidator.setSchemaFilePath( schemaPath );
	    _subflowValidator.setSchemaBaseUri( rootUri );
	}
}