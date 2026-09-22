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

		describe( "objectHasAggregateRelationships()", function(){
			it( "should return true when the object has a one-to-many or many-to-many property", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					gallery = { relationship="many-to-many", relatedTo="asset" }
				} );
				svc.$( "$translatePropertyName", "Gallery" );

				expect( svc.objectHasAggregateRelationships( "elf_test_object" ) ).toBeTrue();
			} );

			it( "should return false when the object has no related collections", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					label = { relationship="none" }
				} );

				expect( svc.objectHasAggregateRelationships( "elf_test_object" ) ).toBeFalse();
			} );
		} );

		describe( "objectHasRelatedDataRelationships()", function(){
			it( "should return true when the object has a many-to-one property", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				svc.$( "$translatePropertyName", "Logo" );

				expect( svc.objectHasRelatedDataRelationships( "elf_test_object" ) ).toBeTrue();
			} );

			it( "should return false when the object has no many-to-one properties", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					gallery = { relationship="many-to-many", relatedTo="asset" }
				} );

				expect( svc.objectHasRelatedDataRelationships( "elf_test_object" ) ).toBeFalse();
			} );
		} );

		describe( "listRelatedDataRelationshipPaths()", function(){
			it( "should include nested many-to-one hops", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset_folder" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					  title        = { relationship="none", type="string" }
					, asset_folder = { relationship="many-to-one", relatedTo="asset_folder" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset_folder" ).$results( {
					label = { relationship="none", type="string" }
				} );
				svc.$( "$translatePropertyName" ).$args( "elf_test_object", "logo" ).$results( "Logo" );
				svc.$( "$translatePropertyName" ).$args( "asset", "asset_folder" ).$results( "Folder" );

				var paths = svc.listRelatedDataRelationshipPaths( "elf_test_object" );
				var ids   = [];
				for( var path in paths ) {
					ArrayAppend( ids, path.id );
				}

				expect( ids ).toInclude( "logo" );
				expect( ids ).toInclude( "logo.asset_folder" );
			} );
		} );

		describe( "listRelatedDataTreeNodes()", function(){
			it( "should list only many-to-one relationships at the root", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					  label = { relationship="none", type="string" }
					, logo  = { relationship="many-to-one", relatedTo="asset" }
					, gallery = { relationship="many-to-many", relatedTo="asset" }
				} );
				svc.$( "$translatePropertyName" ).$args( "elf_test_object", "logo" ).$results( "Logo" );

				var nodes = svc.listRelatedDataTreeNodes( "elf_test_object" );
				var ids   = [];
				for( var node in nodes ) {
					ArrayAppend( ids, node.id );
				}

				expect( ids ).toInclude( "logo" );
				expect( ids ).notToInclude( "label" );
				expect( ids ).notToInclude( "gallery" );
				expect( nodes[ 1 ].type ).toBe( "relationship" );
				expect( nodes[ 1 ].hasChildren ).toBeTrue();
				expect( nodes[ 1 ].property ).toBe( "logo" );
			} );

			it( "should include fields, custom fields, formula fields and nested many-to-one hops", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset_folder" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					  title        = { relationship="none", type="string" }
					, nickname     = { relationship="none", type="string", formula="( select shorttext_value from _cfv_pobj_asset where record = ${prefix}id )", customField=true, customFieldLabel="Nickname" }
					, asset_folder = { relationship="many-to-one", relatedTo="asset_folder" }
					, versions     = { relationship="one-to-many", relatedTo="asset_version" }
				} );
				svc.$( "$translatePropertyName" ).$args( "asset", "title" ).$results( "Title" );
				svc.$( "$translatePropertyName" ).$args( "asset", "asset_folder" ).$results( "Folder" );

				var nodes = svc.listRelatedDataTreeNodes( "elf_test_object", "logo" );
				var byId  = {};
				for( var node in nodes ) {
					byId[ node.id ] = node;
				}

				expect( byId ).toHaveKey( "logo.title" );
				expect( byId ).toHaveKey( "logo.nickname" );
				expect( byId ).toHaveKey( "logo.asset_folder" );
				expect( byId ).notToHaveKey( "logo.versions" );
				expect( byId[ "logo.title" ].type ).toBe( "property" );
				expect( byId[ "logo.nickname" ].label ).toBe( "Nickname" );
				expect( byId[ "logo.asset_folder" ].type ).toBe( "relationship" );
				expect( byId[ "logo.asset_folder" ].hasChildren ).toBeTrue();
				expect( byId[ "logo.asset_folder" ].relationshipPath ).toBe( "logo" );
				expect( byId[ "logo.asset_folder" ].property ).toBe( "asset_folder" );
				expect( nodes[ 1 ].type ).toBe( "relationship" );
				expect( nodes[ ArrayLen( nodes ) ].type ).toBe( "property" );
			} );

			it( "should not offer further hops once the maximum depth is reached", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset_folder" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					asset_folder = { relationship="many-to-one", relatedTo="asset_folder" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset_folder" ).$results( {
					  label         = { relationship="none", type="string" }
					, parent_folder = { relationship="many-to-one", relatedTo="asset_folder" }
				} );
				svc.$( "$translatePropertyName" ).$args( "asset_folder", "label" ).$results( "Label" );
				svc.$( "$translatePropertyName" ).$args( "asset_folder", "parent_folder" ).$results( "Parent folder" );

				var nodes = svc.listRelatedDataTreeNodes(
					  objectName       = "elf_test_object"
					, relationshipPath = "logo.asset_folder.parent_folder"
					, maxHops          = 3
				);
				var byId = {};
				for( var node in nodes ) {
					byId[ node.id ] = node;
				}

				expect( byId ).toHaveKey( "logo.asset_folder.parent_folder.label" );
				expect( byId ).toHaveKey( "logo.asset_folder.parent_folder.parent_folder" );
				expect( byId[ "logo.asset_folder.parent_folder.parent_folder" ].hasChildren ).toBeFalse();
			} );
		} );

		describe( "getRelatedDataSelectionLabel()", function(){
			it( "should join translated relationship hops and the terminal field", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					title = { relationship="none", type="string" }
				} );
				svc.$( "$translatePropertyName" ).$args( "elf_test_object", "logo" ).$results( "Logo" );
				svc.$( "$translatePropertyName" ).$args( "asset", "title" ).$results( "Title" );

				expect( svc.getRelatedDataSelectionLabel( "elf_test_object", "logo", "title" ) ).toBe( "Logo → Title" );
			} );
		} );
			it( "should resolve a field on a related record, including formula properties", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					nickname = { relationship="none", type="string", formula="( select shorttext_value from _cfv_pobj_asset where record = ${prefix}id )", customFieldLabel="Nickname" }
				} );

				var resolved = svc.resolveRelatedDataPath( "elf_test_object", "logo", "nickname" );

				expect( resolved.valid ).toBeTrue();
				expect( resolved.path ).toBe( "logo.nickname" );
				expect( resolved.relatedObject ).toBe( "asset" );
				expect( resolved.formula ).toInclude( "${prefix}id" );
			} );

			it( "should reject a one-to-many collection as the source field", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "objectExists" ).$args( "asset" ).$results( true );
				variables.mockPoService.$( "getObjectProperties" ).$args( "elf_test_object" ).$results( {
					logo = { relationship="many-to-one", relatedTo="asset" }
				} );
				variables.mockPoService.$( "getObjectProperties" ).$args( "asset" ).$results( {
					versions = { relationship="one-to-many", relatedTo="asset_version" }
				} );

				expect( svc.resolveRelatedDataPath( "elf_test_object", "logo", "versions" ).valid ).toBeFalse();
			} );
		} );

		describe( "getRelatedObjectForAggregateProperty()", function(){
			it( "should return the relatedTo of the collection property", function(){
				var svc = _getService();

				variables.mockPoService.$( "objectExists" ).$args( "elf_test_object" ).$results( true );
				variables.mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = "elf_test_object"
					, propertyName  = "gallery"
					, attributeName = "relatedTo"
					, defaultValue  = ""
				).$results( "asset" );

				expect( svc.getRelatedObjectForAggregateProperty( "elf_test_object", "gallery" ) ).toBe( "asset" );
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
