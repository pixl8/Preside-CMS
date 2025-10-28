component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow renderer", function() {

			beforeEach( function(){
				_webflowLibrary      = CreateEmptyMock( "preside.system.services.webflow.spec.WebflowSpecLibrary" );
				_configService       = CreateEmptyMock( "preside.system.services.webflow.WebflowConfigurationService" );
				_instanceService     = CreateEmptyMock( "preside.system.services.webflow.WebflowInstanceService" );
				_actionsService      = CreateEmptyMock( "preside.system.services.webflow.WebflowActionsService" );
				_formsService        = CreateStub();
				_coldbox             = CreateStub();
				_event               = CreateStub();
				_rc                  = { test=CreateUUId() }
				_webflowLayoutArgs   = {}
				_formContext         = CreateUUId();
				_formAdminContext    = CreateUUId();
				_formFieldLayout     = CreateUUId();
				_formFieldsetLayout  = CreateUUId();
				_formTabLayout       = CreateUUId();
				_formLayout          = CreateUUId();
				_includeValidationJs = true;
				_validationJsRef     = "presideJQuery";

				_renderer = CreateMock( object=new preside.system.services.webflow.WebflowRenderer(
					  webflowLibrary          = _webflowLibrary
					, webflowInstanceService  = _instanceService
					, webflowConfigurator     = _configService
					, webflowActionsService   = _actionsService
					, formsService            = _formsService
					, webflowLayoutArgs       = _webflowLayoutArgs
					, formContext             = _formContext
					, formAdminContext        = _formAdminContext
					, formFieldLayout         = _formFieldLayout
					, formFieldsetLayout      = _formFieldsetLayout
					, formTabLayout           = _formTabLayout
					, formLayout              = _formLayout
					, formIncludeValidationJs = _includeValidationJs
					, formJqueryRef           = _validationJsRef
				) );

				_renderer.$( "$getColdbox", _coldbox );
				_renderer.$( "$getRequestContext", _event );
				_renderer.$( "$announceInterception" );
				_event.$( "getCollection", _rc );
				_event.$( "isAdminRequest", false );
			} );

			describe( "renderStep( webflowId, instanceRef, webflowStep, workflowInstance  )", function(){
				beforeEach( function() {
					_step = CreateMock( object=new preside.system.services.webflow.spec.WebflowStep() );
					_instance = CreateMock( object=new cfflow.models.instances.WorkflowInstance() );
					_state = { test=CreateUUId() };
					_webflowId = CreateUUId();
					_instanceRef = CreateUUId();
					_stepId = CreateUUId();
					_stepConfig = { stepConfig=CreateUUId() };

					_formsService.$( "formExists", false );
					_coldbox.$( "viewletExists", false );

					_step.setId( _stepId );

					_instance.$( "getState", _state );
				} );
				it( "should render the explicitly defined viewlet defined on the step", function(){
					var rendered = CreateUUId();

					_step.setDisplay( { viewlet = { event="test.event" } } );
					_coldbox.$( "runEvent", rendered );

					expect( _renderer.renderStep( _webflowId, _instanceRef, _step, _instance, _stepConfig ) ).toBe( rendered );
					var callLog = _coldbox.$callLog().runEvent;
					expect( callLog.len() ).toBe( 1 );
					expect( callLog[ 1 ].event ).toBe( "test.event" );
					expect( callLog[ 1 ].private ).toBe( true );
					expect( callLog[ 1 ].prePostExempt ).toBe( true );
					expect( callLog[ 1 ].eventArguments.args ).toBe( { state=_state, stepConfig=_stepConfig, webflowId=_webflowId, stepId=_stepId, instanceRef=_instanceRef } );
					expect( callLog[ 1 ].eventArguments.wfInstance ).toBe( _instance );
				} );
				it( "should render the explicitly defined form defined on the step", function(){
					var rendered = CreateUUId();

					_step.setDisplay( { form = "some.test.form" } );

					_formsService.$( "renderForm" ).$args(
						  formName              = "some.test.form"
						, context               = _formContext
						, fieldLayout           = _formFieldLayout
						, fieldsetLayout        = _formFieldsetLayout
						, tabLayout             = _formTabLayout
						, formLayout            = _formLayout
						, formId                = "webflow-#_webflowId#-#_instanceRef#-#_stepId#"
						, validationResult      = ""
						, includeValidationJs   = _includeValidationJs
						, validationJsJqueryRef = _validationJsRef
						, savedData             = _state
						, additionalArgs        = {}
					).$results( rendered );

					expect( _renderer.renderStep( _webflowId, _instanceRef, _step, _instance, _stepConfig ) ).toBe( rendered );
				} );

				it( "should render the convention based viewlet when exists and no explicit viewlet defined", function(){
					var rendered = CreateUUId();

					_step.setDisplay( {} );

					_coldbox.$( "viewletExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( true );
					_coldbox.$( "runEvent", rendered );

					expect( _renderer.renderStep( _webflowId, _instanceRef, _step, _instance, _stepConfig ) ).toBe( rendered );
					var callLog = _coldbox.$callLog().runEvent;
					expect( callLog.len() ).toBe( 1 );
					expect( callLog[ 1 ].event ).toBe( "webflow.#_webflowId#.#_stepId#" );
					expect( callLog[ 1 ].private ).toBe( true );
					expect( callLog[ 1 ].prePostExempt ).toBe( true );
					expect( callLog[ 1 ].eventArguments.args ).toBe( { state=_state, stepConfig=_stepConfig, webflowId=_webflowId, stepId=_stepId, instanceRef=_instanceRef } );
					expect( callLog[ 1 ].eventArguments.wfInstance ).toBe( _instance );
				} );
				it( "should render the convention based form when exists and no explicit form defined", function(){
					var rendered = CreateUUId();

					_step.setDisplay( {} );

					_coldbox.$( "viewletExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( false );
					_formsService.$( "formExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( true );

					_formsService.$( "renderForm" ).$args(
						  formName              = "webflow.#_webflowId#.#_stepId#"
						, context               = _formContext
						, fieldLayout           = _formFieldLayout
						, fieldsetLayout        = _formFieldsetLayout
						, tabLayout             = _formTabLayout
						, formLayout            = _formLayout
						, formId                = "webflow-#_webflowId#-#_instanceRef#-#_stepId#"
						, validationResult      = ""
						, includeValidationJs   = _includeValidationJs
						, validationJsJqueryRef = _validationJsRef
						, savedData             = _state
						, additionalArgs        = {}
					).$results( rendered );

					expect( _renderer.renderStep( _webflowId, _instanceRef, _step, _instance, _stepConfig ) ).toBe( rendered );
				} );
				it( "should render any forms first if they exist and pass them into any existing viewlet", function(){
					var renderedForm = CreateUUId();
					var rendered = CreateUUId();

					_step.setDisplay( {} );

					_coldbox.$( "viewletExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( true );
					_formsService.$( "formExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( true );

					_formsService.$( "renderForm" ).$args(
						  formName              = "webflow.#_webflowId#.#_stepId#"
						, context               = _formContext
						, fieldLayout           = _formFieldLayout
						, fieldsetLayout        = _formFieldsetLayout
						, tabLayout             = _formTabLayout
						, formLayout            = _formLayout
						, formId                = "webflow-#_webflowId#-#_instanceRef#-#_stepId#"
						, validationResult      = ""
						, includeValidationJs   = _includeValidationJs
						, validationJsJqueryRef = _validationJsRef
						, savedData             = _state
						, additionalArgs        = {}
					).$results( renderedForm );
					_coldbox.$( "runEvent", rendered );;

					expect( _renderer.renderStep( _webflowId, _instanceRef, _step, _instance, _stepConfig ) ).toBe( rendered );
					var callLog = _coldbox.$callLog().runEvent;
					expect( callLog.len() ).toBe( 1 );
					expect( callLog[ 1 ].event ).toBe( "webflow.#_webflowId#.#_stepId#" );
					expect( callLog[ 1 ].private ).toBe( true );
					expect( callLog[ 1 ].prePostExempt ).toBe( true );
					expect( callLog[ 1 ].eventArguments.args ).toBe( { state=_state, stepConfig=_stepConfig, renderedForm=renderedForm, webflowId=_webflowId, stepId=_stepId, instanceRef=_instanceRef } );
					expect( callLog[ 1 ].eventArguments.wfInstance ).toBe( _instance );
				} );
				it( "should return an empty string when no target renderer is defined or exists by convention", function(){
					var rendered = CreateUUId();

					_step.setDisplay( {} );

					_coldbox.$( "viewletExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( false );
					_formsService.$( "formExists" ).$args( "webflow.#_webflowId#.#_stepId#" ).$results( false );

					expect( _renderer.renderStep( _webflowId, _instanceRef, _step, _instance, _stepConfig ) ).toBe( "" );
				} );
			} );

			describe( "renderLayout( layout, layoutArgs, renderedStep, webflow, step, instance, stepCopy, webflowArgs )", function() {
				beforeEach( function() {
					_webflow     = CreateMock( object=new preside.system.services.webflow.spec.Webflow() );
					_step        = CreateMock( object=new preside.system.services.webflow.spec.WebflowStep() );
					_instance    = CreateMock( object=new cfflow.models.instances.WorkflowInstance() );
					_state       = { test=CreateUUId() };
					_webflowId   = CreateUUId();
					_instanceRef = CreateUUId();
					_stepId      = CreateUUId();
					_webflowArgs = { test=CreateUUId() }

					_step.setId( _stepId );

					_instance.$( "getState", _state );
				} );

				it( "should run the coldbox viewlet indicated by 'layout', passing info about next/prev steps + step content", function(){
					var rendered = CreateUUId();
					var renderedStep = CreateUUId();
					var webflowId = CreateUUId();
					var instanceRef = CreateUUId();
					var subReference = CreateUUId();
					var layout   = "some.test.layout";
					var stepCopy = { step="copy", isntit=CreateUUId() };
					var args = { test=CreateUUId() };

					_actionsService.$( "hasNextAction", true );
					_actionsService.$( "hasPrevAction", true );

					_coldbox.$( "renderViewlet", rendered );


					expect( _renderer.renderLayout(
						  layoutViewlet = layout
						, layoutArgs    = args
						, webflowId     = webflowId
						, instanceRef   = instanceRef
						, subReference  = subReference
						, renderedStep  = renderedStep
						, stepConfig    = stepCopy
						, webflow       = _webflow
						, step          = _step
						, instance      = _instance
						, webflowArgs   = _webflowArgs
					) ).toBe( rendered );

					var log = _coldbox.$callLog().renderViewlet;
					expect( log.len() ).toBe( 1 );
					expect( log[ 1 ].event ).toBe( layout );
					expect( log[ 1 ].args ).toBe( {
						  webflowId    = webflowId
						, instanceRef  = instanceRef
						, subReference = subReference
						, state        = _state
						, hasNext      = true
						, hasPrev      = true
						, stepConfig   = stepCopy
						, step         = _step
						, webflow      = _webflow
						, renderedStep = renderedStep
						, test         = args.test
						, webflowArgs  = _webflowArgs
						, canCancel    = false
					} );

				} );
			} );

		} );
	}

}