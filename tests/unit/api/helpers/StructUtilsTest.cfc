component extends="testbox.system.BaseSpec" {


	function run(){
		describe( "cleanStruct() helper function", function(){
			it( "should return a cleaned struct with byte arrays removed", function(){
				include "/preside/system/helpers/structUtils.cfm";

				var inputStruct = {
					  booleanTest = false
					, stringTest  = "Test"
					, arrayTest   = [ "one", "two", "three", ToBinary( ToBase64("I am a string.") ) ]
					, structTest  = { one="one", two="two", three="three" , byteArray=ToBinary( ToBase64("I am a string.") ) }
				};

				var expectedStruct = {
					  booleanTest = false
					, stringTest  = "Test"
					, arrayTest   = [ "one", "two", "three" ]
					, structTest  = { one="one", two="two", three="three" }
				};
				cleanStruct( inputStruct );
				expect(  inputStruct ).toBe( expectedStruct );
			} );
		} );

	}
}