component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "Boolean display", function(){
			it( "should render icons for the check and cross mode", function(){
				var renderer = _getBooleanRenderer( {} );

				expect( renderer.admin( args=_args( true  ) ) ).toInclude( "fa-check-circle" );
				expect( renderer.admin( args=_args( false ) ) ).toInclude( "fa-times-circle" );
				expect( renderer.admin( args=_args( ""    ) ) ).toInclude( "fa-question" );
			} );

			it( "should render words for the yes/no and true/false modes", function(){
				expect( _getBooleanRenderer( { booleanDisplay="yesNo" } ).admin( args=_args( true ) ) ).toBe( "Yes" );
				expect( _getBooleanRenderer( { booleanDisplay="trueFalse" } ).admin( args=_args( false ) ) ).toBe( "False" );
				expect( _getBooleanRenderer( { booleanDisplay="yesNo" } ).admin( args=_args( "" ) ) ).toBe( "Not set" );
			} );

			it( "should render a coloured badge with the configured wording", function(){
				var renderer = _getBooleanRenderer( {
					  booleanDisplay = "customBadge"
					, trueLabel      = "Signed up"
					, trueColour     = "##ff0000"
					, falseLabel     = "Not yet"
					, falseColour    = "##ffffff"
				} );

				var whenTrue = renderer.admin( args=_args( true ) );

				expect( whenTrue ).toInclude( ">Signed up</span>" );
				expect( whenTrue ).toInclude( "background-color:##ff0000;" );
				expect( whenTrue ).toInclude( "color:##fff;" );
				expect( renderer.admin( args=_args( false ) ) ).toInclude( "color:##333;" );
			} );

			it( "should render nothing for a badge with no wording", function(){
				var renderer = _getBooleanRenderer( { booleanDisplay="customBadge", trueLabel="Yes" } );

				expect( renderer.admin( args=_args( "" ) ) ).toBe( "" );
			} );
		} );

		describe( "Date display", function(){
			it( "should use the admin user's own format for the system default", function(){
				var renderer = _getDateRenderer( {}, "date" );

				expect( renderer.default( event=_getEventStub(), args=_args( "2026-09-24" ) ) ).toBe( "24/09/2026" );
			} );

			it( "should fall back to the site format when there is no admin user", function(){
				var renderer = _getDateRenderer( {}, "date" );

				expect( renderer.default( args=_args( "2026-09-24" ) ) ).toBe( "24 Sep 2026" );
			} );

			it( "should use the preset mask when one is chosen", function(){
				var renderer = _getDateRenderer( { dateDisplay="long" }, "date" );

				expect( renderer.default( event=_getEventStub(), args=_args( "2026-09-24" ) ) ).toBe( "24 September 2026" );
			} );

			it( "should append the time for datetime fields", function(){
				var renderer = _getDateRenderer( { dateDisplay="long" }, "datetime" );

				expect( renderer.default( event=_getEventStub(), args=_args( "2026-09-24 14:30:00" ) ) ).toInclude( "14:30:00" );
			} );

			it( "should pass non dates straight through", function(){
				expect( _getDateRenderer( {}, "date" ).default( args=_args( "not a date" ) ) ).toBe( "not a date" );
			} );

			it( "should render relative time using the datetime relative renderer", function(){
				var renderer = _getDateRenderer( { dateDisplay="relative" }, "datetime" );

				renderer.$( "renderContent", "20 minutes ago" );

				expect( renderer.default( event=_getEventStub(), args=_args( "2026-09-24 14:30:00" ) ) ).toBe( "20 minutes ago" );

				var admin = renderer.admin( event=_getEventStub(), args=_args( "2026-09-24 14:30:00" ) );

				expect( admin ).toInclude( ">20 minutes ago</abbr>" );
				expect( admin ).toInclude( "24&##x2f;09&##x2f;2026" );
			} );

			it( "should never use relative time when exporting", function(){
				var renderer = _getDateRenderer( { dateDisplay="relative" }, "datetime" );

				renderer.$( "renderContent", "20 minutes ago" );

				var exported = renderer.dataexport( event=_getEventStub(), args=_args( "2026-09-24 14:30:00" ) );

				expect( exported ).toBe( "24/09/2026 14:30:00" );
				expect( exported ).notToInclude( "ago" );
			} );
		} );

		describe( "Number display", function(){
			it( "should group thousands by default and drop grouping on request", function(){
				expect( _getNumberRenderer( {}, "integer" ).default( args=_args( 1250000 ) ) ).toBe( "1,250,000" );
				expect( _getNumberRenderer( { useGrouping=false }, "integer" ).default( args=_args( 1250000 ) ) ).toBe( "1250000" );
			} );

			it( "should honour an explicit number of decimal places", function(){
				expect( _getNumberRenderer( { decimalPlaces="3" }, "float" ).default( args=_args( 1.5 ) ) ).toBe( "1.500" );
			} );

			it( "should default floats to two decimal places", function(){
				expect( _getNumberRenderer( {}, "float" ).default( args=_args( 1.5 ) ) ).toBe( "1.50" );
			} );

			it( "should add a percent sign without scaling the stored value", function(){
				expect( _getNumberRenderer( { numberDisplay="percentage" }, "integer" ).default( args=_args( 45 ) ) ).toBe( "45%" );
			} );

			it( "should abbreviate large numbers in compact mode", function(){
				var renderer = _getNumberRenderer( { numberDisplay="compact" }, "integer" );

				expect( renderer.default( args=_args( 12500     ) ) ).toBe( "12.5customFields:number.compact.thousand" );
				expect( renderer.default( args=_args( 3400000   ) ) ).toBe( "3.4customFields:number.compact.million" );
				expect( renderer.default( args=_args( 999       ) ) ).toBe( "999" );
			} );

			it( "should format currency using a real locale rather than the generic currency sign", function(){
				var rendered = _getNumberRenderer( { numberDisplay="currency" }, "integer" ).default( args=_args( 1250 ) );

				expect( rendered ).notToInclude( Chr( 164 ) );
				expect( rendered ).toInclude( "1,250.00" );
			} );

			it( "should wrap the result in the configured prefix and suffix", function(){
				expect( _getNumberRenderer( { prefix="~", suffix=" pts" }, "integer" ).default( args=_args( 12 ) ) ).toBe( "~12 pts" );
			} );

			it( "should pass non numeric values straight through", function(){
				expect( _getNumberRenderer( {}, "integer" ).default( args=_args( "n/a" ) ) ).toBe( "n/a" );
			} );
		} );
	}

	private struct function _args( required any data ) {
		return { data=arguments.data, objectName="elf_test_object", propertyName="cf_field" };
	}

	private any function _getBooleanRenderer( required struct config ) {
		var renderer = CreateMock( object=new preside.system.handlers.renderers.content.CustomFieldBoolean() );
		var words    = {
			  "cms:boolean.yes"            = "Yes"
			, "cms:boolean.no"             = "No"
			, "cms:boolean.not.set"        = "Not set"
			, "customFields:boolean.true"  = "True"
			, "customFields:boolean.false" = "False"
		};

		renderer.$property( propertyName="presideObjectService"   , mock=_getPropertyStub( "boolean", arguments.config ) );
		renderer.$property( propertyName="customFieldTypesService", mock=_getTypesService() );
		renderer.$property( propertyName="customFieldBadgeService", mock=new preside.system.services.customFields.CustomFieldBadgeService() );
		renderer.$( method="translateResource", callback=function( uri ){ return words[ arguments.uri ] ?: arguments.uri; } );

		return renderer;
	}

	private any function _getDateRenderer( required struct config, required string dataType ) {
		var renderer = CreateMock( object=new preside.system.handlers.renderers.content.CustomFieldDate() );
		var masks    = {
			  "customFields:dateFormat.short"  = "dd/mm/yyyy"
			, "customFields:dateFormat.medium" = "dd mmm yyyy"
			, "customFields:dateFormat.long"   = "dd mmmm yyyy"
			, "cms:dateFormat"                 = "dd mmm yyyy"
			, "cms:timeFormat"                 = "HH:mm:ss"
		};

		renderer.$property( propertyName="presideObjectService"   , mock=_getPropertyStub( arguments.dataType, arguments.config ) );
		renderer.$property( propertyName="customFieldTypesService", mock=_getTypesService() );
		renderer.$( method="translateResource", callback=function( uri ){ return masks[ arguments.uri ] ?: arguments.uri; } );

		return renderer;
	}

	private any function _getNumberRenderer( required struct config, required string dataType ) {
		var renderer = CreateMock( object=new preside.system.handlers.renderers.content.CustomFieldNumber() );
		var words    = { "customFields:number.currency.locale" = "en_GB" };

		renderer.$property( propertyName="presideObjectService"   , mock=_getPropertyStub( arguments.dataType, arguments.config ) );
		renderer.$property( propertyName="customFieldTypesService", mock=_getTypesService() );
		renderer.$( method="translateResource", callback=function( uri ){ return words[ arguments.uri ] ?: arguments.uri; } );

		return renderer;
	}

	private any function _getEventStub() {
		var stub = createStub();

		stub.$( "getAdminUserDetails", { user_admin_date_format="dd/mm/yyyy", user_time_format="24h" } );

		return stub;
	}

	private any function _getTypesService() {
		return new preside.system.services.customFields.CustomFieldTypesService( configuredTypes={} );
	}

	private any function _getPropertyStub( required string dataType, required struct config ) {
		var stub = createStub();

		stub.$( "getObjectPropertyAttribute" ).$args(
			  objectName    = "elf_test_object"
			, propertyName  = "cf_field"
			, attributeName = "customFieldDataType"
		).$results( arguments.dataType );
		stub.$( "getObjectPropertyAttribute" ).$args(
			  objectName    = "elf_test_object"
			, propertyName  = "cf_field"
			, attributeName = "customFieldDisplayConfig"
		).$results( SerializeJson( arguments.config ) );

		return stub;
	}

}
