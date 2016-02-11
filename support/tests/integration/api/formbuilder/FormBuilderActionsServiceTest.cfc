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
					  { id="email"  , title="email title"  , iconclass="email icon"  , description="email description"   }
					, { id="slack"  , title="slack title"  , iconclass="slack icon"  , description="slack description"   }
					, { id="webhook", title="webhook title", iconclass="webhook icon", description="webhook description" }
				] );
			} );
		} );
	}

	private function getService( array configuredActions=[] ) {
		var service = CreateMock( object=new preside.system.services.formbuilder.FormBuilderActionsService(
			configuredActions = arguments.configuredActions
		) );

		service.$( "$translateResource", "" );

		return service;
	}

}