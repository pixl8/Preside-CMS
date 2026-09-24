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

		describe( "getDisplayConfig()", function(){
			it( "should return an empty struct for data types with no display options", function(){
				expect( _getService().getDisplayConfig( "text" ) ).toBe( {} );
			} );

			it( "should return defaults when no config has been stored", function(){
				var config = _getService().getDisplayConfig( "boolean" );

				expect( config.booleanDisplay ).toBe( "checkCross" );
				expect( config.trueLabel ).toBe( "" );
			} );

			it( "should fall back to defaults when the stored config is not valid json", function(){
				var config = _getService().getDisplayConfig( dataType="date", typeConfig="not json at all" );

				expect( config.dateDisplay ).toBe( "systemDefault" );
			} );

			it( "should apply stored settings and drop unknown keys", function(){
				var config = _getService().getDisplayConfig(
					  dataType   = "boolean"
					, typeConfig = '{"booleanDisplay":"customBadge","trueLabel":" Active ","nonsense":"ignored"}'
				);

				expect( config.booleanDisplay ).toBe( "customBadge" );
				expect( config.trueLabel ).toBe( "Active" );
				expect( StructKeyExists( config, "nonsense" ) ).toBeFalse();
			} );

			it( "should reject values that are not in the allowed set", function(){
				var config = _getService().getDisplayConfig( dataType="integer", typeConfig='{"numberDisplay":"bananas"}' );

				expect( config.numberDisplay ).toBe( "standard" );
			} );

			it( "should accept relative as a date display option", function(){
				var config = _getService().getDisplayConfig( dataType="datetime", typeConfig='{"dateDisplay":"relative"}' );

				expect( config.dateDisplay ).toBe( "relative" );
			} );

			it( "should clamp decimal places to the supported range", function(){
				var svc = _getService();

				expect( svc.getDisplayConfig( dataType="float", typeConfig='{"decimalPlaces":"99"}' ).decimalPlaces ).toBe( "10" );
				expect( svc.getDisplayConfig( dataType="float", typeConfig='{"decimalPlaces":"-3"}' ).decimalPlaces ).toBe( "0" );
				expect( svc.getDisplayConfig( dataType="float", typeConfig='{"decimalPlaces":"lots"}' ).decimalPlaces ).toBe( "" );
			} );

			it( "should accept a struct of form data as well as stored json", function(){
				var config = _getService().getDisplayConfig( dataType="integer", typeConfig={ numberDisplay="currency", useGrouping=false } );

				expect( config.numberDisplay ).toBe( "currency" );
				expect( config.useGrouping ).toBeFalse();
			} );
		} );

		describe( "isDefaultDisplayConfig()", function(){
			it( "should recognise an untouched config", function(){
				var svc = _getService();

				expect( svc.isDefaultDisplayConfig( "date", svc.getDisplayConfig( "date" ) ) ).toBeTrue();
			} );

			it( "should recognise a customised config", function(){
				var svc    = _getService();
				var config = svc.getDisplayConfig( dataType="date", typeConfig='{"dateDisplay":"long"}' );

				expect( svc.isDefaultDisplayConfig( "date", config ) ).toBeFalse();
			} );
		} );

		describe( "getDisplayRenderer()", function(){
			it( "should map each display group onto its renderer", function(){
				var svc = _getService();

				expect( svc.getDisplayRenderer( "boolean"  ) ).toBe( "customFieldBoolean" );
				expect( svc.getDisplayRenderer( "datetime" ) ).toBe( "customFieldDate" );
				expect( svc.getDisplayRenderer( "float"    ) ).toBe( "customFieldNumber" );
				expect( svc.getDisplayRenderer( "text"     ) ).toBe( "" );
			} );
		} );

		describe( "buildTypeConfig()", function(){
			it( "should serialise only the settings that belong to the data type", function(){
				var json = _getService().buildTypeConfig( dataType="date", formData={ dateDisplay="short", prefix="nope" } );

				expect( json ).toInclude( "short" );
				expect( json ).notToInclude( "nope" );
			} );

			it( "should return an empty string for data types with no display options", function(){
				expect( _getService().buildTypeConfig( dataType="lookup", formData={ dateDisplay="short" } ) ).toBe( "" );
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
