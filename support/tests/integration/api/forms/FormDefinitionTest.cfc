component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run(){

		describe( "getRawDefinition()", function(){

			it( "should return a struct with nothing but a tabs key that is an empty array, when nothing passed to the defintion object's constructor", function(){
				var definition = _getFormDefinition().getRawDefinition();

				expect( definition ).toBe( { tabs=[] } );
			} );

			it( "should return the structure passed to the object's constructor when no modifying actions made", function(){
				var raw        = { tabs=[ { id="test", fieldsets=[] } ] };
				var definition = _getFormDefinition( raw ).getRawDefinition();

				expect( definition ).toBe( raw );
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