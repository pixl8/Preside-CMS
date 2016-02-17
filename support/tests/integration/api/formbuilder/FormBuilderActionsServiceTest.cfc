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
					  { id="email"  , title="email title"  , iconclass="email icon"  , description="email description"  , configFormName="formbuilder.actions.email" }
					, { id="slack"  , title="slack title"  , iconclass="slack icon"  , description="slack description"  , configFormName="formbuilder.actions.slack" }
					, { id="webhook", title="webhook title", iconclass="webhook icon", description="webhook description", configFormName="formbuilder.actions.webhook" }
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
					  id             = "slack"
					, title          = "slack title"
					, iconclass      = "slack icon"
					, description    = "slack description"
					, configFormName = "formbuilder.actions.slack"
				} );
			} );

			it( "should return an empty struct when the action is not registered", function(){
				var actions = [ "email", "slack", "webhook" ];
				var action  = "idonotexist";
				var service = getService( actions );

				expect( service.getActionConfig( action ) ).toBe( {} );
			} );
		} );
	}

	private function getService( array configuredActions=[] ) {
		variables.mockValidationEngine = createEmptyMock( "preside.system.services.validation.ValidationEngine" );
		variables.mockFormsService     = createEmptyMock( "preside.system.services.forms.FormsService" );
		variables.mockActionDao        = createStub();

		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderActionsService(
			  configuredActions = arguments.configuredActions
			, validationEngine  = mockValidationEngine
			, formsService      = mockFormsService
		) );

		service.$( "$translateResource", "" );
		service.$( "$getPresideObject" ).$args( "formbuild_formaction" ).$results( mockActionDao );

		return service;
	}

}