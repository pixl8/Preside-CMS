/**
 * @presideService true
 * @singleton      true
 */
component {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API METHODS
	public void function run() {
		$announceInterception( "onPresideHeartbeat" );

		systemOutput( getApplicationMetadata() );
	}
}