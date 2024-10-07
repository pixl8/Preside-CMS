/**
 * @singletone     true
 * @presideservice true
 */
component {

	function init() {
		return this;
	}

	function test() {
		if ( $isExtensionInstalled( "myextension" ) ) {
			return $getPresideObject( "my_extension_object" ).selectData( selectFields=[ "label" ], returnType="array" );
		}

		return [];
	}
}