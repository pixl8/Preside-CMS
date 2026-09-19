component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getValueObjectName()", function(){
			it( "should prefix the host object name with _cfv_", function(){
				expect( _getService().getValueObjectName( "my_table" ) ).toBe( "_cfv_my_table" );
			} );
		} );

		describe( "getValueTableName()", function(){
			it( "should prefix the host table name with _cfv_", function(){
				expect( _getService().getValueTableName( "pobj_my_table" ) ).toBe( "_cfv_pobj_my_table" );
			} );
		} );

		describe( "createValueObjectMeta()", function(){
			it( "should name the value table with a _cfv_ prefix on the host table", function(){
				var meta = _getService().createValueObjectMeta( "my_table", {
					  tableName   = "pobj_my_table"
					, tablePrefix = "pobj_"
					, dsn         = "preside"
					, idField     = "id"
					, properties  = {
						id = { type="string", dbtype="varchar", maxLength=35 }
					  }
				} );

				expect( meta.name ).toBe( "_cfv_my_table" );
				expect( meta.tableName ).toBe( "_cfv_pobj_my_table" );
				expect( meta.versioned ).toBeFalse();
				expect( meta.properties.id.generator ).toBe( "increment" );
				expect( meta.properties.record.relatedto ).toBe( "my_table" );
				expect( meta.properties.record.ondelete ).toBe( "cascade" );
				expect( meta.properties.field.relatedto ).toBe( "custom_field" );
				expect( meta.properties.field.type ).toBe( "numeric" );
				expect( meta.properties.field.dbtype ).toBe( "bigint" );
			} );
		} );

		describe( "addValueObjects()", function(){
			it( "should register a value object for each opted-in host", function(){
				var svc     = _getService();
				var objects = {
					my_table = {
						meta = {
							  customFieldsEnabled = true
							, tableName           = "pobj_my_table"
							, tablePrefix         = "pobj_"
							, properties          = { id={ type="string", dbtype="varchar", maxLength=35 } }
						}
					}
					, other = {
						meta = {
							  customFieldsEnabled = false
							, tableName           = "pobj_other"
							, properties          = { id={ type="string", dbtype="varchar", maxLength=35 } }
						}
					}
				};

				svc.addValueObjects( objects );

				expect( StructKeyExists( objects, "_cfv_my_table" ) ).toBeTrue();
				expect( objects._cfv_my_table.instance ).toBe( "auto_created" );
				expect( objects._cfv_my_table.meta.tableName ).toBe( "_cfv_pobj_my_table" );
				expect( StructKeyExists( objects, "_cfv_other" ) ).toBeFalse();
			} );
		} );

		describe( "decorateHostVersionObjects()", function(){
			it( "should add _version_custom_fields to the host version object only", function(){
				var objects = {
					my_table = {
						meta = {
							  customFieldsEnabled = true
							, versioned           = true
							, versionObjectName   = "vrsn_my_table"
							, properties          = {}
						}
					}
					, vrsn_my_table = {
						meta = {
							  properties    = {}
							, propertyNames = [ "id" ]
							, dbFieldList   = "id"
						}
					}
				};

				_getService().decorateHostVersionObjects( objects );

				expect( StructKeyExists( objects.vrsn_my_table.meta.properties, "_version_custom_fields" ) ).toBeTrue();
				expect( objects.vrsn_my_table.meta.properties._version_custom_fields.dbtype ).toBe( "text" );
				expect( ListFindNoCase( objects.vrsn_my_table.meta.dbFieldList, "_version_custom_fields" ) ).toBeGT( 0 );
				expect( StructKeyExists( objects.my_table.meta.properties, "_version_custom_fields" ) ).toBeFalse();
			} );
		} );
	}

	private any function _getService() {
		var svc     = CreateMock( object=new preside.system.services.customFields.CustomFieldsValueTableService() );
		var helpers = createStub();

		helpers.$( method="isTrue", callback=function( val ){
			return IsBoolean( arguments.val ?: "" ) && arguments.val;
		} );

		svc.$property( propertyName="presideObjectService", mock=createStub() );
		svc.$property( propertyName="sqlRunner"           , mock=createStub() );
		svc.$property( propertyName="$helpers"            , mock=helpers );

		return svc;
	}

}
