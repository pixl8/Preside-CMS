/**
 * @feature        webflow
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	/**
	 * @webflowLibrary.inject webflowSpecLibrary
	 * @formsService.inject   formsService
	 *
	 */
	public any function init( required any webflowLibrary, required any formsService ) {
		_setWebflowLibrary( arguments.webflowLibrary );
		_setFormsService( arguments.formsService );

		return this;
	}

// PUBLIC API METHODS
	public void function initializeSingleton( required string webflowId ) {
		var webflow       = _getWebflowLibrary().getWebflow( arguments.webflowId );
		var confRecord    = _getExistingSingletonFlowForStartupCheck( arguments.webflowId );
		var confId        = confRecord.id ?: "";

		if ( StructIsEmpty( confRecord ) ) {
			var flowMeta     = webflow.getMeta();
			var defaultLabel = flowMeta.title ?: arguments.webflowId;

			confId = $getPresideObject( "webflow_configuration" ).insertData({
				  webflow_id       = arguments.webflowId
				, label            = $translateResource( uri="webflow.#arguments.webflowId#:title", defaultValue=defaultLabel )
				, is_singleton     = true
				, is_admin_flow    = webflow.getAdminFlow()
				, hide_from_widget = webflow.getAdminFlow() ? true : ( webflow.getHideFromWidget() ? true : false )
			});
		}

		if ( StructIsEmpty( confRecord ) || confRecord.weflow_config_hash != webflow.getConfigHash() ) {
			_syncStepConfigs( confId, webflow.getSteps(), _getExistingStepConfigs( arguments.webflowId ) );
			$getPresideObject( "webflow_configuration" ).updateData( id=confId, data={ weflow_config_hash=webflow.getConfigHash() } );
		}

		return;
	}

	public void function ensureSingletonAdminFlagUpdated( required string webflowId ) {
		var webflow    = _getWebflowLibrary().getWebflow( arguments.webflowId );
		var confRecord = _getExistingSingletonFlowForStartupCheck( arguments.webflowId );

		if ( webflow.getAdminFlow() ) {
			$getPresideObject( "webflow_configuration" ).updateData(
				  data         = { is_admin_flow=true, hide_from_widget=true }
				, filter       = "webflow_id = :webflow_id AND is_singleton = :is_singleton AND ( is_admin_flow IS NULL OR is_admin_flow = :is_admin_flow )"
				, filterParams = {
					  webflow_id    = arguments.webflowId
					, is_singleton  = true
					, is_admin_flow = false
				}
			);
		} else if ( webflow.getHideFromWidget() != $helpers.isTrue( confRecord.hide_from_widget ?: "" ) ) {
			$getPresideObject( "webflow_configuration" ).updateData(
				  data         = { hide_from_widget=webflow.getHideFromWidget() }
				, filter       = "webflow_id = :webflow_id AND is_singleton = :is_singleton AND ( is_admin_flow IS NULL OR is_admin_flow = :is_admin_flow )"
				, filterParams = {
					  webflow_id    = arguments.webflowId
					, is_singleton  = true
					, is_admin_flow = false
				}
			);
		}
	}

	public void function initializeStep( required string stepId ) {
		if ( !_stepExistsForStartupCheck( arguments.stepId ) ) {
			$getPresideObject( "webflow_configuration_step" ).insertData({ step_id = arguments.stepId });
		}
	}

	public void function createConfiguration(
		  required string webflowId
		, required string label
		, required string instanceRef
		, required struct config
		,          string siteId = ""
	) {
		var webflow = _getWebflowLibrary().getWebflow( arguments.webflowId );
		var flowDao = $getPresideObject( "webflow_configuration" );

		if ( webflow.getSingleton() ) {
			throw( "The webflow, [#webflowId#], is a singleton and cannot have multiple configuration instances. Please use initializeSingleton() instead.", "preside.webflow.singleton.flow"  );
		}

		if ( _webflowConfigSiteTenanted() ) {
			var sites = Len( Trim( arguments.siteId ) ) ? $getPresideObject( "site" ).selectData( id=arguments.siteId ) : $getPresideObject( "site" ).selectData();
			var existingSteps = "";
			for( var site in sites ) {
				var confRecord = _getExistingNonSingletonFlowForStartupCheck( arguments.webflowId, arguments.instanceRef, site.id );
				var confId     = confRecord.id ?: "";

				if ( StructIsEmpty( confRecord ) ) {
					confId = flowDao.insertData( bypassTenants=[ "site" ], data={
						  webflow_id   = arguments.webflowId
						, label        = arguments.label
						, instance_ref = arguments.instanceRef
						, is_singleton = false
						, config       = SerializeJson( config )
						, site         = site.id
					} );
				}

				if ( StructIsEmpty( confRecord ) || confRecord.weflow_config_hash != webflow.getConfigHash() ) {
					if ( IsSimpleValue( existingSteps ) ) {
						existingSteps = _getExistingStepConfigs( arguments.webflowId, arguments.instanceRef );
					}
					_syncStepConfigs( confId, webflow.getSteps(), existingSteps, site.id );
					flowDao.updateData( id=confId, data={ weflow_config_hash=webflow.getConfigHash() } );
				}
			}
		} else {
			var confRecord = _getExistingNonSingletonFlowForStartupCheck( arguments.webflowId, arguments.instanceRef );
			var confId     = confRecord.id ?: "";

			if ( StructIsEmpty( confRecord ) ) {
				confId = flowDao.insertData({
					  webflow_id   = arguments.webflowId
					, label        = arguments.label
					, instance_ref = arguments.instanceRef
					, is_singleton = false
					, config       = SerializeJson( config )
				});
			}

			if ( StructIsEmpty( confRecord ) || confRecord.weflow_config_hash != webflow.getConfigHash() ) {
				_syncStepConfigs( confId, webflow.getSteps(), _getExistingStepConfigs( arguments.webflowId, arguments.instanceRef ) );
				flowDao.updateData( id=confId, data={ weflow_config_hash=webflow.getConfigHash() } );
			}
		}

		return;
	}

	public numeric function saveFlowConfig(
		  required string webflowId
		, required struct config
		,          string instanceRef
	) {
		var flowDao = $getPresideObject( "webflow_configuration" );
		var filter  = { webflow_id=arguments.webflowId, instance_ref=arguments.instanceRef };

		return flowDao.updateData( data={ config=SerializeJson( arguments.config ) }, filter=filter );
	}

	public struct function getFlowConfig(
		  required string webflowId
		,          string instanceRef = ""
	) {
		var flowDao = $getPresideObject( "webflow_configuration" );
		var filter  = { webflow_id=arguments.webflowId, instance_ref=arguments.instanceRef };
		var record = flowDao.selectData( filter=filter );

		for( var r in record ) {
			try {
				var config = DeserializeJson( record.config );
				if ( IsStruct( config ) ) {
					StructAppend( r, config );
				}
			} catch( any e ) {}

			return r;
		}

		return {};
	}

	public string function getFlowConfigForm( required string webflowId ) {
		var flow = _getWebflowLibrary().getWebFlow( arguments.webflowId );
		var initConfig = flow.getInit();
		var explicitForm = initConfig.state.configForm ?: "";

		if ( Len( Trim( explicitForm ) ) ) {
			return explicitForm;
		}

		var conventionBasedForm = "webflow.#webflowId#.config";
		if ( _getFormsService().formExists( conventionBasedForm ) ) {
			return conventionBasedForm;
		}

		return "";
	}

	public array function getSubflowConfigForms( required string webflowId ) {
		var flow         = _getWebflowLibrary().getWebFlow( arguments.webflowId );
		var flowSteps    = flow.getSteps();
		var allSubflows  = "";
		var subflowForms = [];

		for ( var step in flowSteps ) {
			allSubflows = listAppend( allSubflows, step.getParentSubflowRef() );
		}

		for ( var subflow in listRemoveDuplicates( allSubflows ) ) {
			var conventionBasedForm = "webflow.subflow.#subflow#.config";

			if ( _getFormsService().formExists( conventionBasedForm ) ) {
				subflowForms.append( conventionBasedForm );
			}
		}

		return subflowForms;
	}

	public string function getStepConfigForm( required string webflowId, required string stepId ) {
		if ( Len( arguments.webflowId ) ) {
			var flow = _getWebflowLibrary().getWebFlow( arguments.webflowId );
			var step = "";
			var found = false;
			for( var step in flow.getSteps() ) {
				if ( step.getId() == arguments.stepId ) {
					found = true;
					break;
				}
			}
			if ( !found ) {
				return "";
			}
		} else {
			var step = _getWebflowLibrary().getStep( arguments.stepId );
		}

		var stepConfigForm = "";
		var explicitForm   = step.getConfigForm();

		if ( Len( Trim( explicitForm ) ) ) {
			stepConfigForm = explicitForm;
		}

		var formsService        = _getFormsService();
		var conventionBasedForm = "";
		if ( Len( webflowId ) && formsService.formExists( "webflow.#webflowId#.#arguments.stepId#.config" ) ) {
			conventionBasedForm = "webflow.#webflowId#.#arguments.stepId#.config";
		}
		if ( !Len( conventionBasedForm ) && formsService.formExists( "webflow.step.#arguments.stepId#.config" ) ) {
			conventionBasedForm = "webflow.step.#arguments.stepId#.config";
		}

		if ( Len( conventionBasedForm ) ) {
			if ( Len( Trim( stepConfigForm ) ) ) {
				stepConfigForm = formsService.getMergedFormName( formName=stepConfigForm, mergeWithFormName=conventionBasedForm );
			} else {
				stepConfigForm = conventionBasedForm;
			}
		}

		return stepConfigForm;
	}

	public numeric function saveStepConfig(
		  required string webflowId
		, required string stepId
		, required struct config
		,          string instanceRef
	) {
		var flowDao = $getPresideObject( "webflow_configuration" );
		var stepDao = $getPresideObject( "webflow_configuration_step" );
		var filter  = { webflow_id=arguments.webflowId, instance_ref=arguments.instanceRef };
		var flowRecord = flowDao.selectData( selectFields=[ "id" ], filter=filter );

		return stepDao.updateData( data=arguments.config, filter={
			  webflow = flowRecord.id
			, step_id = arguments.stepId
		} );
	}

	public struct function getStepConfig(
		  required string webflowId
		, required string stepId
		,          string instanceRef = ""
	) {
		var step    = _getStepDefinition( argumentCollection=arguments );
		var config  = step.getConfig(); // config defined in yml (rest below is user provided)
		var flowDao = $getPresideObject( "webflow_configuration" );
		var stepDao = $getPresideObject( "webflow_configuration_step" );

		if ( Len( arguments.webflowId ) ) {
			var filter  = { webflow_id=arguments.webflowId, instance_ref=arguments.instanceRef };
			var flowRecord = flowDao.selectData( selectFields=[ "id" ], filter=filter );
			var stepFilter = { step_id=arguments.stepId };

			if ( flowRecord.recordcount ) {
					stepFilter.webflow = flowRecord.id;
			} else {
					stepFilter[ "webflow.webflow_id" ] = arguments.webflowId;
			}

			var stepRecord = stepDao.selectData( filter=stepFilter );
		} else {
			var stepRecord = stepDao.selectData( filter={
				  webflow = ""
				, step_id = arguments.stepId
			} );
		}

		for( var sr in stepRecord ) {
			try {
				StructAppend( sr, DeserializeJson( sr.config ?: "" ), false );
			} catch( any e ){}

			if ( Len( Trim( arguments.webflowId ) ) ) {
				var step = _getWebflowLibrary().getWebflowStep( arguments.webflowId, arguments.stepId );
				if ( Len( step.getStepRef() ) ) {
					var parentConfig = getStepConfig( webflowId="", stepId=step.getStepRef() );

					_mergeStructsOverwritingEmptyValues( sr, parentConfig );
				}
			}

			StructAppend( config, sr, false );
			break;
		}

		return config;
	}

	public struct function getStepCopy(
		  required string webflowId
		, required string stepId
		,          string instanceRef
	) {
		var copyConfig      = getStepConfig( argumentCollection=arguments );
		var flowBaseI18nUri = "webflow.#arguments.webflowId#:";
		var stepBaseI18nUri = "webflow.step.#arguments.stepId#:";
		var globalDefault   = "";
		var flowDefault     = "";

		if ( !Len( Trim( copyConfig.label ?: "" ) ) ) {
			copyConfig.label = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.label"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.label ?: "" ) ) ) {
				copyConfig.label = $translateResource(
					  uri          = stepBaseI18nUri & "label"
					, defaultValue = arguments.stepId
				);
			}
		}

		if ( !Len( Trim( copyConfig.title ?: "" ) ) ) {
			copyConfig.title = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.title"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.title ?: "" ) ) ) {
				copyConfig.title = $translateResource(
					  uri          = stepBaseI18nUri & "title"
					, defaultValue = arguments.stepId
				);
			}
		}
		if ( !Len( Trim( copyConfig.short_title ?: "" ) ) ) {
			copyConfig.short_title = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.title.short"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.short_title ?: "" ) ) ) {
				copyConfig.short_title = $translateResource(
					  uri          = stepBaseI18nUri & "title.short"
					, defaultValue = copyConfig.title
				);
			}
		}
		if ( !Len( Trim( copyConfig.intro ?: "" ) ) ) {
			copyConfig.intro = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.intro"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.intro ?: "" ) ) ) {
				copyConfig.intro = $translateResource(
					  uri          = stepBaseI18nUri & "intro"
					, defaultValue = ""
				);
			}
		}
		if ( !Len( Trim( copyConfig.next_button ?: "" ) ) ) {
			globalDefault = $translateResource( uri="webflow:next", defaultValue="Next" );
			flowDefault = $translateResource( uri=flowBaseI18nUri & "defaults.next", defaultValue=globalDefault );
			copyConfig.next_button = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.next.btn"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.next_button ?: "" ) ) ) {
				copyConfig.next_button = $translateResource(
					  uri          = stepBaseI18nUri & "next.btn"
					, defaultValue = flowDefault
				);
			}
		}
		if ( !Len( Trim( copyConfig.back_button ?: "" ) ) ) {
			globalDefault = $translateResource( uri="webflow:back", defaultValue="Back" );
			flowDefault = $translateResource( uri=flowBaseI18nUri & "defaults.back", defaultValue=globalDefault );
			copyConfig.back_button = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.back.btn"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.back_button ?: "" ) ) ) {
				copyConfig.back_button = $translateResource(
					  uri          = stepBaseI18nUri & "back.btn"
					, defaultValue = flowDefault
				);
			}
		}
		if ( !Len( Trim( copyConfig.cancel_button ?: "" ) ) ) {
			globalDefault = $translateResource( uri="webflow:cancel", defaultValue="Cancel" );
			flowDefault = $translateResource( uri=flowBaseI18nUri & "defaults.cancel", defaultValue=globalDefault );
			copyConfig.cancel_button = $translateResource(
				  uri          = flowBaseI18nUri & "step.#arguments.stepId#.cancel.btn"
				, defaultValue = ""
			);

			if ( !Len( Trim( copyConfig.cancel_button ?: "" ) ) ) {
				copyConfig.cancel_button = $translateResource(
					  uri          = stepBaseI18nUri & "cancel.btn"
					, defaultValue = flowDefault
				);
			}
		}

		return copyConfig;
	}

	public struct function getStepTitles(
		  required string  webflowId
		, required string  instanceRef
		,          boolean short = false
	) {
		var titles      = {};
		var baseI18nUri = "webflow.#arguments.webflowId#:step.";
		var flowDao     = $getPresideObject( "webflow_configuration" );
		var flowRecord  = flowDao.selectData( selectFields=[ "id" ], filter={ webflow_id=arguments.webflowId, instance_ref=arguments.instanceRef } );
		var stepDao     = $getPresideObject( "webflow_configuration_step" );
		var stepFilter  = {};

		if ( flowRecord.recordcount ) {
			stepFilter.webflow = flowRecord.id;
		} else {
			stepFilter[ "webflow.webflow_id" ] = arguments.webflowId;
		}

		var stepRecords = stepDao.selectData( selectFields = [ "step_id", "title", "short_title" ], filter=stepFilter );
		var stepDefinitions = _getWebflowLibrary().getWebflow( webflowId ).getSteps();
		var parentSteps = [];
		var parentStepRecords = "";

		for( var step in stepDefinitions ) {
			if ( Len( Trim( step.getStepRef() ) ) ) {
				parentSteps.append( step.getStepRef() );
			}
		}
		if ( ArrayLen( parentSteps ) ) {
			parentStepRecords = stepDao.selectData(
				  selectFields = [ "step_id", "title", "short_title" ]
				, filter       = { webflow = "", step_id=parentSteps }
			);
		}

		for( var step in stepRecords ) {
			var stepBaseI18nUri = "webflow.step.#step.step_id#:";
			var parent          = {};
			var title           = "";

			for( var p in parentStepRecords ) {
				if ( p.step_id == step.step_id ) {
					parent = p;
					break;
				}
			}

			if ( arguments.short ) {
				title = step.short_title;
				if ( !Len( Trim( title ) ) ) {
					title = parent.short_title ?: "";
					if ( !Len( Trim( title ) ) ) {
						title = $translateResource(
							  uri          = baseI18nUri & "#step.step_id#.title.short"
							, defaultValue = $translateResource( uri=stepBaseI18nUri & "title.short", defaultValue="" )
						);
					}
				}
			}
			if ( !Len( Trim( title ) ) ) {
				title = step.title;
				if ( !Len( Trim( title ) ) ) {
					title = parent.title ?: "";
					if ( !Len( Trim( title ) ) ) {
						title = $translateResource(
							  uri          = baseI18nUri & "#step.step_id#.title"
							, defaultValue = $translateResource( uri=stepBaseI18nUri & "title", defaultValue="" )
						);
					}
				}
			}

			if ( !Len( Trim( title ) ) ) {
				title = step.step_id;
			}

			titles[ step.step_id ] = title;
		}

		return titles;
	}

	public string function getStepLabel( required string stepId, string webflowId="" ) {
		var i18nUri = "webflow.step.#stepId#:label";
		var defaultValue = stepId;

		if ( Len( arguments.webflowId ) ) {
			var step   = _getWebflowLibrary().getWebflowStep( webflowId, stepId );
			var parentStepId = step.getStepRef();

			i18nUri = "webflow.#webflowId#:step.#arguments.stepId#.label";

			if ( Len( parentStepId ) ) {
				defaultValue = $translateResource( uri="webflow.step.#parentStepId#:label", defaultValue=stepId );
			}
		}


		return $translateResource( uri=i18nUri, defaultValue=defaultValue );
	}

	public string function getStepDescription( required string stepId, string webflowId="" ) {
		var i18nUri = "webflow.step.#stepId#:description";
		var defaultValue = "";

		if ( Len( arguments.webflowId ) ) {
			var step   = _getWebflowLibrary().getWebflowStep( webflowId, stepId );
			var parentStepId = step.getStepRef();

			i18nUri = "webflow.#webflowId#:step.#arguments.stepId#.description";

			if ( Len( parentStepId ) ) {
				defaultValue = $translateResource( uri="webflow.step.#parentStepId#:description", defaultValue="" );
			}
		}

		return $translateResource( uri=i18nUri, defaultValue=defaultValue );
	}

	public struct function getInstanceRefGroupingConfig(
		  required string  webflowId
		,          string  sourceObject        = "cfflow_workflow_instance"
		,          boolean includeNonSingleton = false
	) {
		var webflow     = _getWebflowLibrary().getWebflow( arguments.webflowId );
		var isSingleton = webflow.getSingleton();

		if ( isSingleton || arguments.includeNonSingleton ) {
			var cb              = $getColdbox();
			var instRefConfig   = webflow.getInstRefConfig();
			var groupingViewlet = Len( instRefConfig.groupingConfigViewlet ?: "" ) ? instRefConfig.groupingConfigViewlet : "webflow.#webflowId#.instanceReferenceAdminGrouping";
			var groupedInstRefs = $getPresideObject( arguments.sourceObject ).selectData(
				  filter       = "reference = :reference AND sub_reference IS NOT NULL"
				, filterParams = { reference=arguments.webflowId }
				, groupBy      = "sub_reference"
				, selectFields = [
					  "sub_reference AS reference_id"
					, "COUNT( id ) AS total_no"
					, "GROUP_CONCAT( datemodified ) AS last_actives"
				]
			);
			var groupingConfig  = {
				  webflowId   = arguments.webflowId
				, groupedRefs = groupedInstRefs
			};

			if ( cb.viewletExists( groupingViewlet ) ) {
				var args         = Duplicate( arguments );
				    args.webflow = webflow;

				StructAppend( groupingConfig, cb.renderViewlet( event=groupingViewlet, args=args ) );
			}

			return groupingConfig;
		}
		return {};
	}

// PRIVATE HELPERS
	private void function _syncStepConfigs( required string flowConfigId, required array steps, required struct existingStepConfigs, string siteId="" ) {
		var stepDao         = $getPresideObject( "webflow_configuration_step" );
		var isSiteTenanted  = ListFindNoCase( $getPresideObjectService().getObjectAttribute( "webflow_configuration_step", "tenant" ), "site" );
		var stepIds         = [];
		var currentSiteId   = isSiteTenanted ? ( Len( arguments.siteId ) ? arguments.siteId : $getRequestContext().getSiteId() ) : "";
		var existingRecords = isSiteTenanted ? ( arguments.existingStepConfigs[ currentSiteId ] ?: {} ) : arguments.existingStepConfigs;

		for( var i=1; i<=ArrayLen( arguments.steps ); i++ ) {
			var step         = arguments.steps[ i ];
			var existingStep = existingRecords[ step.getId() ] ?: {};

			ArrayAppend( stepIds, step.getId() );

			if ( StructCount( existingStep ) ) {
				var data = {
					  sort_order    = i
					, position_type = _getPositionType( step, i, ArrayLen( arguments.steps ) )
				};

				if ( data.sort_order != existingStep.sort_order || data.position_type != existingStep.position_type ) {
					stepDao.updateData(
						  id            = existingStep.id
						, data          = data
						, bypassTenants = [ "site" ]
					);
				}
			} else {
				var data = {
					  webflow       = arguments.flowConfigId
					, step_id       = step.getId()
					, sort_order    = i
					, position_type = _getPositionType( step, i, ArrayLen( arguments.steps ) )
				};
				if ( isSiteTenanted ) {
					data.site = currentSiteId;
				}

				stepDao.insertData( data=data, bypassTenants=[ "site" ] );
			}
		}

		if ( ArrayLen( stepIds ) ) {
			stepDao.deleteData(
				  filter        =  "webflow = :webflow and step_id not in (:step_id)"
				, filterParams  =  { webflow=arguments.flowConfigId, step_id=stepIds }
				, bypassTenants = [ "site" ]
			);
		}
	}

	private string function _getPositionType( required WebflowStep step, required numeric stepIndex, required numeric stepCount ) {
		if ( arguments.stepIndex == arguments.stepCount || arguments.step.getFinish() ) {
			return "end";
		}
		if ( arguments.stepIndex == 1 || arguments.step.getStart() ) {
			return "start";
		}

		return "middle";
	}

	private void function _mergeStructsOverwritingEmptyValues( required struct child, required struct parent ) {
		StructAppend( child, parent, false );
		for( var key in child ) {
			if ( IsSimpleValue( child[ key ] ) && IsEmpty( child[ key ] ) )  {
				child[ key ] = parent[ key ] ?: "";
			}

			if ( IsStruct( child[ key ] ) && IsStruct( parent[ key ] ?: "" ) ) {
				_mergeStructsOverwritingEmptyValues( child[ key ], parent[ key ] );
			}
		}
	}

	private WebflowStep function _getStepDefinition( required string webflowId, required string stepId ) {
		if ( Len( Trim( arguments.webflowId ) ) ) {
			return _getWebflowLibrary().getWebflowStep( arguments.webflowId, arguments.stepId );
		}

		return _getWebflowLibrary().getStep( arguments.stepId );
	}

	private struct function _getExistingStepConfigs( required string webflowId, string instanceRef="" ) {
		var selectFields = [ "id", "step_id", "sort_order", "position_type" ];
		var isSiteTenanted = ListFindNoCase( $getPresideObjectService().getObjectAttribute( "webflow_configuration_step", "tenant" ), "site" );

		if ( isSiteTenanted ) {
			ArrayAppend( selectFields, "site" );
		}

		var filter = { "webflow.webflow_id"=arguments.webflowId };
		if( Len( Trim( arguments.instanceRef ) ) ) {
			filter[ "webflow.instance_ref" ] = arguments.instanceRef;
		}

		var steps = $getPresideObject( "webflow_configuration_step" ).selectData(
			  selectFields  = selectFields
			, filter        = filter
			, bypassTenants = [ "site" ]
		);
		var mapped = {};

		for( var step in steps ) {
			if ( isSiteTenanted ) {
				mapped[ step.site ] = mapped[ step.site ] ?: {};
				mapped[ step.site ][ step.step_id ] = step;
			} else {
				mapped[ step.step_id ] = step;
			}
		}

		return mapped;
	}

	private struct function _getExistingSingletonFlowForStartupCheck( required string webflowId ) {
		if ( !StructKeyExists( request, "_webflowSingletonsStartupCache" ) ) {
			request._webflowSingletonsStartupCache = {};

			var rawflows = $getPresideObject( "webflow_configuration" ).selectData( filter="instance_ref is null" );
			for( var f in rawFlows ) {
				request._webflowSingletonsStartupCache[ f.webflow_id ] = f;
			}
		}

		return request._webflowSingletonsStartupCache[ arguments.webflowId ] ?: {};
	}

	private struct function _getExistingNonSingletonFlowForStartupCheck( required string webflowId, required string instanceRef, string siteId="" ) {
		var isSiteTenanted = _webflowConfigSiteTenanted();

		if ( !StructKeyExists( request, "_webflowNonSingletonsStartupCache" ) ) {
			request._webflowNonSingletonsStartupCache = {};

			var rawflows = $getPresideObject( "webflow_configuration" ).selectData( filter="instance_ref is not null", bypassTenants=[ "site" ] );
			for( var f in rawFlows ) {
				if ( !StructKeyExists( request._webflowNonSingletonsStartupCache, f.webflow_id ) ) {
					request._webflowNonSingletonsStartupCache[ f.webflow_id ] = {};
				}

				if ( isSiteTenanted && !StructKeyExists( request._webflowNonSingletonsStartupCache[ f.webflow_id ], f.instance_ref ) ) {
					request._webflowNonSingletonsStartupCache[ f.webflow_id ][ f.instance_ref ] = {};
				}

				if ( isSiteTenanted ) {
					request._webflowNonSingletonsStartupCache[ f.webflow_id ][ f.instance_ref ][ f.site ] = f;
				} else {
					request._webflowNonSingletonsStartupCache[ f.webflow_id ][ f.instance_ref ] = f;
				}
			}
		}

		if ( isSiteTenanted ) {
			return request._webflowNonSingletonsStartupCache[ arguments.webflowId ][ arguments.instanceRef ][ arguments.siteId ] ?: {};
		}

		return request._webflowNonSingletonsStartupCache[ arguments.webflowId ][ arguments.instanceRef ] ?: {};
	}

	private boolean function _stepExistsForStartupCheck( required string stepId ) {
		if ( !StructKeyExists( request, "_webflowStepsStartupCache" ) ) {
			request._webflowStepsStartupCache = {};

			var rawSteps = $getPresideObject( "webflow_configuration_step" ).selectData( filter="webflow is null", selectFields=[ "step_id" ] );
			for( var s in rawSteps ) {
				request._webflowStepsStartupCache[ s.step_id ] = true;
			}
		}

		return StructKeyExists( request._webflowStepsStartupCache, arguments.stepId );
	}



	private function _webflowConfigSiteTenanted() {
		if ( !StructKeyExists( variables, "_webflowConfigIsSiteTenanted" ) ) {
			variables._webflowConfigIsSiteTenanted = ListFindNoCase( $getPresideObjectService().getObjectAttribute( "webflow_configuration", "tenant" ), "site" );
		}

		return variables._webflowConfigIsSiteTenanted;
	}

// GETTERS AND SETTERS
	private any function _getWebflowLibrary() {
		return _webflowLibrary;
	}
	private void function _setWebflowLibrary( required any webflowLibrary ) {
		_webflowLibrary = arguments.webflowLibrary;
	}

	private any function _getFormsService() {
		return _formsService;
	}
	private void function _setFormsService( required any formsService ) {
		_formsService = arguments.formsService;
	}
}