component extends="testbox.system.BaseSpec" {

	function run() {
		describe( "Webflow submission service", function() {

			beforeEach( function(){
				_webflowLibrary   = CreateEmptyMock( "preside.system.services.webflow.spec.WebflowSpecLibrary" );
				_actionsService   = CreateEmptyMock( "preside.system.services.webflow.WebflowActionsService" );
				_actionsService   = CreateEmptyMock( "preside.system.services.webflow.WebflowActionsService" );
				_configService    = CreateEmptyMock( "preside.system.services.webflow.WebflowConfigurationService" );

				_instanceService  = CreateEmptyMock( "preside.system.services.webflow.WebflowInstanceService" );
				_instance         = CreateEmptyMock( "cfflow.models.instances.WorkflowInstance" );
				_validationResult = CreateStub();
				_requestContext   = CreateStub();
				_coldbox          = CreateStub();
				_requestService   = CreateStub();
				_flash            = CreateStub();

				_svc = CreateMock( object=new preside.system.services.webflow.WebflowSubmissionService(
					  webflowLibrary  = _webflowLibrary
					, actionsService  = _actionsService
					, instanceService = _instanceService
					, configService   = _configService
				) );
				_svc.$helpers = CreateStub();

				_webflowId = CreateUUId();
				_instanceRef = CreateUUId();
				_subReference = CreateUUId();
				_submitted = { test=true, data=CreateUUid() };

				_instanceService.$( "getInstance" ).$args( webflowId=_webflowId, instanceRef=_instanceRef, subReference=_subReference, explicitArgs={} ).$results( _instance );
				_svc.$( "$getRequestContext", _requestContext );
				_svc.$( "$getColdbox", _coldbox );
				_requestContext.$( "getCollectionForForm", _submitted );
				_requestContext.$( "getCollectionWithoutSystemVars", _submitted );
				_svc.$helpers.$( "validateForms" ).$args( _submitted ).$results( _validationResult );
				_svc.$helpers.$( "isTrue", true );
				_coldbox.$( "runEvent" );
				_coldbox.$( "handlerExists", false );
				_coldbox.$( "getRequestService", _requestService );
				_requestService.$( "getFlashScope", _flash );
				_validationResult.$( "validated", true );
				_instance.$( "appendState" );
				_instance.$( "doAction" );
				_flash.$( "putAll" );
			} );

			describe( "doNext( webflowId, instanceRef, stepId )", function(){
				beforeEach( function() {
					_stepId = CreateUUId();
					_step = CreateMock( object=new preside.system.services.webflow.spec.WebflowStep() );
					_stepConfig = { test=CreateUUId() };
					_flowConfig = { test=CreateUUId() };
					_instance.$( "getActiveStep", _stepId );
					_actionsService.$( "hasNextAction", true );
					_webflowLibrary.$( "getWebflowStep" ).$args( _webflowId, _stepId ).$results( _step );
					_configService.$( "getStepConfig" ).$args( webflowId=_webflowId, stepId=_stepId, instanceRef=_instanceRef ).$results( _stepConfig );
					_configService.$( "getFlowConfig" ).$args( webflowId=_webflowId, instanceRef=_instanceRef ).$results( _flowConfig );
				} );

				it( "should raise an error if the stepId does not match the currently active step", function(){
					_instance.$( "getActiveStep", CreateUUId() );

					expect( function(){
						_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );
					} ).toThrow( "preside.webflow.step.not.active" );
				} );

				it( "should raise an error if the step does not have a next action", function(){
					_actionsService.$( "hasNextAction", false );

					expect( function(){
						_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );
					} ).toThrow( "preside.webflow.action.not.permitted" );

				} );

				it( "should automatically run validation on any submitted Preside forms", function(){
					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _svc.$helpers.$callLog().validateForms.len() ).toBe( 1 );
					expect( _svc.$helpers.$callLog().validateForms[ 1 ][ 1 ] ).toBe( _submitted );
				} );

				it( "should run explicitly defined submission handler on the flow step", function(){
					var submissionConfig = { handler={ event="test.event", args={ test=CreateUUId() } } };

					_step.$( "getSubmission", submissionConfig );
					_coldbox.$( "handlerExists" ).$args( submissionConfig.handler.event ).$results( true );

					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _coldbox.$callLog().runEvent.len() ).toBe( 1 );
					expect( _coldbox.$callLog().runEvent[ 1 ] ).toBe( {
						  event          = submissionConfig.handler.event
						, private        = true
						, prePostExempt  = true
						, eventArguments = {
							  args             = submissionConfig.handler.args
							, wfInstance       = _instance
							, webflowId        = _webflowId
							, webflowConfig    = _flowConfig
							, instanceRef      = _instanceRef
							, stepId           = _stepId
							, stepConfig       = _stepConfig
							, persistData      = _submitted
							, validationResult = _validationResult
						}
					} );
				} );

				it( "should run convention based submission handler on the flow step if no explicit one defined and handler exists", function(){
					var conventionBasedHandler = "webflow.#_webflowId#.#_stepId#Action";

					_coldbox.$( "handlerExists" ).$args( conventionBasedHandler ).$results( true );

					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _coldbox.$callLog().runEvent.len() ).toBe( 1 );
					expect( _coldbox.$callLog().runEvent[ 1 ] ).toBe( {
						  event          = conventionBasedHandler
						, private        = true
						, prePostExempt  = true
						, eventArguments = {
							  args             = {}
							, wfInstance       = _instance
							, webflowId        = _webflowId
							, webflowConfig    = _flowConfig
							, instanceRef      = _instanceRef
							, stepId           = _stepId
							, stepConfig       = _stepConfig
							, persistData      = _submitted
							, validationResult = _validationResult
						}
					} );
				} );

				it( "should add any submitted preside form state to the the workflow instance state", function(){
					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _instance.$callLog().appendState.len() ).toBe( 1 );
					expect( _instance.$callLog().appendState[ 1 ] ).toBe( [ _submitted ] );
				} );

				it( "should process the 'next' action if all is good", function(){
					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _instance.$callLog().doAction.len() ).toBe( 1 );
					expect( _instance.$callLog().doAction[ 1 ] ).toBe( [ "next", _stepId ] );
				} );

				it( "should not process the 'next' action if validationResult fails", function(){
					_validationResult.$( "validated", false );


					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _instance.$callLog().appendState.len() ).toBe( 0 );
					expect( _instance.$callLog().doAction.len() ).toBe( 0 );
				} );

				it( "should persist any submitted form data + the validation result if validation fails", function(){
					_validationResult.$( "validated", false );

					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					var expectedPersist = StructCopy( _submitted );
					expectedPersist.validationResult = _validationResult;

					expect( _flash.$callLog().putAll.len() ).toBe( 1 );
					expect( _flash.$callLog().putAll[ 1 ].map ).toBe( expectedPersist );
					expect( _flash.$callLog().putAll[ 1 ].saveNow ).toBe( true );

				} );

				it( "should persist auto-trimmed and empty checkbox form data in the workflow instance state", function(){
					var _submittedTrimmed   = { check2="1", email="foo@bar.org" };
					var _submittedUntrimmed = { check1="", check2="1", email=" foo@bar.org " };
					var _expectedState      = { check1="", check2="1", email="foo@bar.org" };

					_validationResult.$( "validated", true );
					_svc.$helpers.$( "validateForms" ).$args( _submittedTrimmed ).$results( _validationResult );

					_requestContext.$( "getCollectionForForm", _submittedTrimmed );
					_requestContext.$( "getCollectionWithoutSystemVars", _submittedUntrimmed );

					_svc.doNext( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _instance.$callLog().appendState.len() ).toBe( 1 );
					expect( _instance.$callLog().appendState[ 1 ] ).toBe( [ _expectedState ] );
				} );

			} );

			describe( "doPrev( webflowId, instanceRef, stepId )", function(){
				beforeEach( function() {
					_stepId = CreateUUId();
					_step = CreateMock( object=new preside.system.services.webflow.spec.WebflowStep() );
					_stepConfig = { test=CreateUUId() };
					_flowConfig = { test=CreateUUId() };
					_instance.$( "getActiveStep", _stepId );
					_actionsService.$( "hasPrevAction", true );
					_webflowLibrary.$( "getWebflowStep" ).$args( _webflowId, _stepId ).$results( _step );
					_configService.$( "getStepConfig" ).$args( webflowId=_webflowId, stepId=_stepId, instanceRef=_instanceRef ).$results( _stepConfig );
					_configService.$( "getFlowConfig" ).$args( webflowId=_webflowId, instanceRef=_instanceRef ).$results( _flowConfig );
				} );

				it( "should raise an error if the stepId does not match the currently active step", function(){
					_instance.$( "getActiveStep", CreateUUId() );

					expect( function(){
						_svc.doPrev( _webflowId, _instanceRef, _subReference, _stepId );
					} ).toThrow( "preside.webflow.step.not.active" );
				} );

				it( "should raise an error if the step does not have a prev action", function(){
					_actionsService.$( "hasPrevAction", false );

					expect( function(){
						_svc.doPrev( _webflowId, _instanceRef, _subReference, _stepId );
					} ).toThrow( "preside.webflow.action.not.permitted" );

				} );

				it( "should process the 'prev' action if all is good", function(){
					_svc.doPrev( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _instance.$callLog().doAction.len() ).toBe( 1 );
					expect( _instance.$callLog().doAction[ 1 ] ).toBe( [ "prev", _stepId ] );
				} );

				it( "should run explicitly defined submission ""back"" handler on the flow step", function(){
					var submissionConfig = { backHandler={ event="test.event", args={ test=CreateUUId() } } };

					_step.$( "getSubmission", submissionConfig );
					_coldbox.$( "handlerExists" ).$args( submissionConfig.backHandler.event ).$results( true );

					_svc.doPrev( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _coldbox.$callLog().runEvent.len() ).toBe( 1 );
					expect( _coldbox.$callLog().runEvent[ 1 ].event         ?: "" ).toBe( submissionConfig.backHandler.event );
					expect( _coldbox.$callLog().runEvent[ 1 ].private       ?: "" ).toBe( true );
					expect( _coldbox.$callLog().runEvent[ 1 ].prePostExempt ?: "" ).toBe( true );

					expect( _coldbox.$callLog().runEvent[ 1 ].eventArguments.args          ?: "" ).toBe( submissionConfig.backHandler.args );
					expect( _coldbox.$callLog().runEvent[ 1 ].eventArguments.webflowId     ?: "" ).toBe( _webflowId                        );
					expect( _coldbox.$callLog().runEvent[ 1 ].eventArguments.instanceRef   ?: "" ).toBe( _instanceRef                      );
					expect( _coldbox.$callLog().runEvent[ 1 ].eventArguments.stepId        ?: "" ).toBe( _stepId                           );
					expect( _coldbox.$callLog().runEvent[ 1 ].eventArguments.webflowConfig ?: "" ).toBe( _flowConfig                       );
					expect( _coldbox.$callLog().runEvent[ 1 ].eventArguments.stepConfig    ?: "" ).toBe( _stepConfig                       );
				} );

				it( "should NOT process the 'prev' action if custom back handler returns false", function(){
					var submissionConfig = { backHandler={ event="test.event", args={ test=CreateUUId() } } };

					_step.$( "getSubmission", submissionConfig );
					_coldbox.$( "handlerExists" ).$args( submissionConfig.backHandler.event ).$results( true );

					_coldbox.$( "runEvent", false );

					_svc.doPrev( _webflowId, _instanceRef, _subReference, _stepId );

					expect( _instance.$callLog().doAction.len() ).toBe( 0 );
				} );
			} );
		} );
	}
}