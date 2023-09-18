/**
 * @restUri    /features/{feature}/
 */
component {
	property name="features" inject="coldbox:setting:features";

	private void function get( required string feature ) {
		if ( StructKeyExists( features, arguments.feature ) ) {
			restResponse.setData( features[ arguments.feature ] );
		} else {
			restResponse.setData( { enabled=false } );
		}
	}
}