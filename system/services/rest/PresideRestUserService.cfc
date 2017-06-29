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
		var dao = $getPresideObject( "rest_user_api_access" );

		transaction {
			dao.deleteData( filter={ rest_user=arguments.userId } );
			for( var api in arguments.apis ) {
				dao.insertData( {
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

	public numeric function regenerateToken( required string userId ) {
		var dao      = $getPresideObject( "rest_user" );
		var newToken = dao.generateToken();

		return dao.updateData( id=arguments.userId, data={ access_token=newToken } );
	}

}
