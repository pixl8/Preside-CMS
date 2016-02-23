component extends="testbox.system.BaseSpec"{

	function run(){
		describe( "listActions", function(){
			it( "should return an empty array when no actions configured", function(){
				var service = getService();

				expect( service.listActions() ).toBe( [] );
			} );

			it( "should return an array of structs with configured action IDs and translated icons, titles and descriptions", function(){
				var actions = [ "email", "slack", "webhook" ];
				var service = getService( actions );

				for( var action in actions ) {
					service.$( "$translateResource" ).$args( uri="formbuilder.actions.#action#:title"      , defaultValue=action    ).$results( "#action# title"       );
					service.$( "$translateResource" ).$args( uri="formbuilder.actions.#action#:description", defaultValue=""        ).$results( "#action# description" );
					service.$( "$translateResource" ).$args( uri="formbuilder.actions.#action#:iconclass"  , defaultValue="fa-send" ).$results( "#action# icon"        );
				}

				expect( service.listActions() ).toBe( [
					  { id="email"  , title="email title"  , iconclass="email icon"  , description="email description"  , configFormName="formbuilder.actions.email"  , submissionHandler="formbuilder.actions.email.onSubmit" }
					, { id="slack"  , title="slack title"  , iconclass="slack icon"  , description="slack description"  , configFormName="formbuilder.actions.slack"  , submissionHandler="formbuilder.actions.slack.onSubmit" }
					, { id="webhook", title="webhook title", iconclass="webhook icon", description="webhook description", configFormName="formbuilder.actions.webhook", submissionHandler="formbuilder.actions.webhook.onSubmit" }
				] );
			} );
		} );

		describe( "getActionConfig", function(){
			it( "should return the configuration struct of the given action", function(){
				var actions = [ "email", "slack", "webhook" ];
				var action  = "slack";
				var service = getService( actions );

				service.$( "$translateResource" ).$args( uri="formbuilder.actions.#action#:title"      , defaultValue=action    ).$results( "#action# title"       );
				service.$( "$translateResource" ).$args( uri="formbuilder.actions.#action#:description", defaultValue=""        ).$results( "#action# description" );
				service.$( "$translateResource" ).$args( uri="formbuilder.actions.#action#:iconclass"  , defaultValue="fa-send" ).$results( "#action# icon"        );

				expect( service.getActionConfig( action ) ).toBe( {
					  id                = "slack"
					, title             = "slack title"
					, iconclass         = "slack icon"
					, description       = "slack description"
					, configFormName    = "formbuilder.actions.slack"
					, submissionHandler = "formbuilder.actions.slack.onSubmit"
				} );
			} );

			it( "should return an empty struct when the action is not registered", function(){
				var actions = [ "email", "slack", "webhook" ];
				var action  = "idonotexist";
				var service = getService( actions );

				expect( service.getActionConfig( action ) ).toBe( {} );
			} );
		} );

		describe( "triggerSubmissionActions", function(){
			it( "should trigger the submission handler for each configured action on the form", function(){
				var actions        = [ "email", "slack", "webhook" ];
				var service        = getService( actions );
				var formId         = CreateUUId();
				var submissionData = { fubar="test", blah=true };
				var savedActions   = [{
					  id            = CreateUUId()
					, action        = { id="slack", submissionHandler="formbuilder.actions.slack.onSubmit" }
					, configuration = { test=CreateUUId() }
				},{
					  id            = CreateUUId()
					, action        = { id="email", submissionHandler="formbuilder.actions.email.onSubmit" }
					, configuration = { sender="bob@email.com", recipients="dianne@test.com" }
				},{
					  id            = CreateUUId()
					, action        = { id="webhook", submissionHandler="formbuilder.actions.webhook.onSubmit" }
					, configuration = { endpoint="http://myhook.com/receiver/" }
				}]

				service.$( "getFormActions" ).$args( formId ).$results( savedActions );
				mockColdbox.$( "runEvent" );

				service.triggerSubmissionActions( formId, submissionData );

				expect( mockColdbox.$callLog().runEvent.len() ).toBe( savedActions.len() );
				for( var i=1; i <= savedActions.len(); i++ ){
					var log = mockColdbox.$callLog().runEvent[ i ];

					expect( log ).toBe( {
						  event          = savedActions[ i ].action.submissionHandler
						, private        = true
						, prePostExempt  = true
						, eventArguments = { args={ configuration=savedActions[ i ].configuration, submissionData=submissionData } }
					} );
				}
			} );
		} );
	}

	private function getService( array configuredActions=[] ) {
		variables.mockValidationEngine = createEmptyMock( "preside.system.services.validation.ValidationEngine" );
		variables.mockFormsService     = createEmptyMock( "preside.system.services.forms.FormsService" );
		variables.mockActionDao        = createStub();
		variables.mockColdbox          = createStub();

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderActionsService(
			  configuredActions = arguments.configuredActions
			, validationEngine  = mockValidationEngine
			, formsService      = mockFormsService
		) );

		service.$( "$translateResource", "" );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$getPresideObject" ).$args( "formbuild_formaction" ).$results( mockActionDao );

		return service;
	}

}