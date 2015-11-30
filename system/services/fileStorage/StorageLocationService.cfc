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


// PRIVATE HELPERS



// GETTERS AND SETTERS


}