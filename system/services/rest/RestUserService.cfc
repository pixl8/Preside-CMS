/**
 * Service for managing multiple authentication providers
 * and authenticating requests
 *
 * @singleton
 * @presideService
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function syncApiAccessForUser( required string userId, required array apis ) {
		var po = $getPresideObject( "rest_user_api_access" );

		transaction {
			po.deleteData( filter={ rest_user=arguments.userId } );
			for( var api in arguments.apis ) {
				po.insertData( {
					  rest_user = arguments.userId
					, api       = api
				} );
			}
		}
	}

	public array function getApiAccessForUser( required string userId ) {
		var records = $getPresideObject( "rest_user_api_access" ).selectData(
			  filter       = { rest_user=arguments.userId }
			, selectFields = [ "api" ]
		);

		return records.recordCount ? ValueArray( records.api ) : [];
	}

}
