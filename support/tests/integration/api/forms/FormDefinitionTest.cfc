component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){

		describe( "getRawDefinition()", function(){

			it( "should return a struct with nothing but a tabs key that is an empty array, when nothing passed to the defintion object's constructor", function(){
				var definition = _getFormDefinition().getRawDefinition();

				expect( definition ).toBe( { tabs=[] } );
			} );

		} );

	}

	private any function _getFormDefinition( struct rawDefinition ) {
		var args = {};

		if ( arguments.keyExists( "rawDefinition" ) ) {
			args.rawDefinition = arguments.rawDefinition;
		}
		return new preside.system.services.forms.FormDefinition( argumentCollection=args );
	}
}