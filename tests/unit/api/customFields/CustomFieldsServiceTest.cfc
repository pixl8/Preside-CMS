component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getFieldListingLabel()", function(){
			it( "should return the field label", function(){
				expect( _getService().getFieldListingLabel( { label="Nickname", key="nickname" } ) ).toBe( "Nickname" );
			} );

			it( "should fall back to the field key when label is missing", function(){
				expect( _getService().getFieldListingLabel( { key="nickname" } ) ).toBe( "nickname" );
			} );
		} );

		describe( "getFieldKeyValidationError()", function(){
			it( "should reject reserved keys", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getIdField" ).$args( "elf_test_object" ).$results( "id" );
				variables.mockPoService.$( "getLabelField" ).$args( "elf_test_object" ).$results( "label" );
				variables.mockPoService.$( "getDateCreatedField" ).$args( "elf_test_object" ).$results( "datecreated" );
				variables.mockPoService.$( "getDateModifiedField" ).$args( "elf_test_object" ).$results( "datemodified" );
				svc.$( "$translateResource", "reserved" );

				expect( Len( svc.getFieldKeyValidationError( "elf_test_object", "id" ) ) ).toBeGT( 0 );
			} );

			it( "should reject malformed keys", function(){
				var svc = _getService();
				svc.$( "$translateResource", "bad format" );

				expect( svc.getFieldKeyValidationError( "elf_test_object", "Bad Key" ) ).toBe( "bad format" );
			} );
		} );
	}

	private any function _getService() {
		var svc     = CreateMock( object=new preside.system.services.customFields.CustomFieldsService() );
		var helpers = createStub();

		variables.mockPoService      = createStub();
		variables.mockTypesService   = createStub();
		variables.mockInjector       = createStub();
		variables.mockValueTables    = createStub();
		variables.mockFormsService   = createStub();
		variables.mockEnumService    = createStub();
		variables.mockFilterService  = createStub();
		variables.mockColdbox        = createStub();

		helpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		variables.mockColdbox.$( "getSetting", { objects={}, fieldTypes={} } );
		svc.$( "$getColdbox", variables.mockColdbox );
		svc.$( "$isFeatureEnabled", true );
		svc.$( "$translateResource", "" );

		svc.$property( propertyName="presideObjectService"         , mock=variables.mockPoService );
		svc.$property( propertyName="customFieldTypesService"      , mock=variables.mockTypesService );
		svc.$property( propertyName="customFieldsPropertyInjector" , mock=variables.mockInjector );
		svc.$property( propertyName="customFieldsValueTableService", mock=variables.mockValueTables );
		svc.$property( propertyName="formsService"                 , mock=variables.mockFormsService );
		svc.$property( propertyName="enumService"                  , mock=variables.mockEnumService );
		svc.$property( propertyName="rulesEngineFilterService"     , mock=variables.mockFilterService );
		svc.$property( propertyName="$helpers"                     , mock=helpers );

		return svc;
	}

}
