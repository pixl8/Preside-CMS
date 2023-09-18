/**
 * @restUri    /features/
 */
component {
	property name="featureService" inject="featureService";

	private void function get() {
		var allFeatures = {};

		for ( var feature in featureService.getAllEnabledFeatures() ) {
			allFeatures[ feature ] = true;
		}

		restResponse.setData( allFeatures );
	}
}