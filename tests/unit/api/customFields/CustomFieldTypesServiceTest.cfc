component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getType()", function(){
			it( "should return the configured type with its id", function(){
				var svc = _getService();

				expect( svc.getType( "integer" ).typedColumn ).toBe( "int_value" );
				expect( svc.getType( "integer" ).id ).toBe( "integer" );
			} );

			it( "should return a text fallback for unknown types", function(){
				var svc  = _getService();
				var type = svc.getType( "unknown" );

				expect( type.control ).toBe( "textinput" );
				expect( type.typedColumn ).toBe( "shorttext_value" );
			} );
		} );

		describe( "mapValueToTypedColumns()", function(){
			it( "should map integers onto int_value", function(){
				var mapped = _getService().mapValueToTypedColumns( "integer", "42" );

				expect( mapped.field_value ).toBe( "42" );
				expect( mapped.int_value ).toBe( 42 );
			} );

			it( "should map booleans onto boolean_value", function(){
				var mapped = _getService().mapValueToTypedColumns( "boolean", true );

				expect( mapped.boolean_value ).toBeTrue();
			} );

			it( "should leave textarea values on field_value only", function(){
				var mapped = _getService().mapValueToTypedColumns( "textarea", "hello" );

				expect( mapped.field_value ).toBe( "hello" );
				expect( StructKeyExists( mapped, "shorttext_value" ) ).toBeFalse();
			} );
		} );
	}

	private any function _getService() {
		return new preside.system.services.customFields.CustomFieldTypesService( configuredTypes={
			  text     = { control="textinput", type="string", typedColumn="shorttext_value", renderer="plaintext" }
			, textarea = { control="textarea" , type="string", typedColumn=""               , renderer="plaintext" }
			, integer  = { control="spinner"  , type="numeric", typedColumn="int_value"     , renderer="integer"   }
			, boolean  = { control="yesNoSwitch", type="boolean", typedColumn="boolean_value", renderer="boolean" }
		} );
	}

}
