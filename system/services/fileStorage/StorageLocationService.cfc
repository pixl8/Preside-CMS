/**
 * @singleton
 * @presideService
 *
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	public any function addLocation(
		  required string name
		, required string storageProvider
		, required struct configuration
	) {
		var data = Duplicate( arguments );

		data.configuration = SerializeJson( data.configuration );

		return $getPresideObject( "asset_storage_location" ).insertData( data );
	}

	public any function updateLocation(
		  required string id
		, required string name
		, required struct configuration
	) {
		var data = Duplicate( arguments );

		data.configuration = SerializeJson( data.configuration );
		data.delete( "id" );

		return $getPresideObject( "asset_storage_location" ).updateData( id=arguments.id, data=data );
	}

	public struct function getLocation( required string id ) {
		if ( Len( Trim( arguments.id ) ) ) {
			var location = $getPresideObject( "asset_storage_location" ).selectData( id=arguments.id );
			for( var l in location ) {
				try {
					l.configuration = DeSerializeJson( l.configuration ?: "" );
				} catch( any e ) {}

				return l;
			}
		}

		return {};
	}


// PRIVATE HELPERS



// GETTERS AND SETTERS


}