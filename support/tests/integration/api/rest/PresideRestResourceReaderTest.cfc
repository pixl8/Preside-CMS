component extends="testbox.system.BaseSpec"{

	function beforeAll() {
		variables.resourceReader = new preside.system.services.rest.PresideRestResourceReader();
	}

	function run(){

		describe( "isValidResource", function(){

			it( "should return false when resource CFC file does not contain a restUri attribute", function(){
				expect( resourceReader.isValidResource( "resources.rest.InvalidResource" ) ).toBeFalse();
			} );

			it( "should return true when the resource CFC file _does_ contain a restUri attribute", function(){
				expect( resourceReader.isValidResource( "resources.rest.DumbButValidResource" ) ).toBeTrue();
			} );

			it( "should return true when the resource CFC file extends a CFC with a restUri attribute", function(){
				expect( resourceReader.isValidResource( "resources.rest.ExtendedDumbButValidResource" ) ).toBeTrue();
			} );

		} );

	}

}