component extends="tests.resources.HelperObjects.PresideBddTestCase" {

	function run() {
		describe( "getRendererForField()", function(){
			it( "should return defined 'adminRenderer' on the property when defined", function(){
				var service = _getService();

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { adminRenderer="whatever", renderer="frontend", type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "whatever" );
			} );

			it( "should return defined 'renderer' on the property when defined and no 'adminRenderer' defined", function(){
				var service = _getService();

				mockPoService.$( "getObjectProperty" ).$args( "testobject", "testprop" ).$results( { renderer="alsdkjf", type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", "testprop" ) ).toBe( "alsdkjf" );
			} );

			it( "should return sensible defaults when properties do not speficy an admin renderer or default renderer", function(){
				var service  = _getService();
				var propName = "";

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="string", dbtype="varchar", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "plaintext" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject2", propName ).$results( { type="string", dbtype="text", relationship="none" } );
				expect( service.getRendererForField( "testobject2", propName ) ).toBe( "richeditor" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject2", propName ).$results( { type="string", dbtype="longtext", relationship="none" } );
				expect( service.getRendererForField( "testobject2", propName ) ).toBe( "richeditor" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject2", propName ).$results( { type="string", dbtype="mediumtext", relationship="none" } );
				expect( service.getRendererForField( "testobject2", propName ) ).toBe( "richeditor" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="date", dbtype="datetime", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "datetime" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="date", dbtype="timestamp", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "datetime" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="date", dbtype="date", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "date" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="boolean", dbtype="boolean", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "boolean" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { type="boolean", dbtype="bit", relationship="none" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "boolean" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-one", relatedto="something" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "manyToOne" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-one", relatedto="asset" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "asset" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-one", relatedto="link" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "link" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="one-to-many", relatedto="blah" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "objectRelatedRecords" );

				propName = "property_" & CreateUUId();
				mockPoService.$( "getObjectProperty" ).$args( "testobject", propName ).$results( { relationship="many-to-many", relatedto="blah" } );
				expect( service.getRendererForField( "testobject", propName ) ).toBe( "objectRelatedRecords" );
			} );
		} );

		describe( "renderField()", function() {
			it( "should call the content renderer for the field, passing in objectName, propertyName and recordId as additional args to the renderer", function(){
				var service      = _getService();
				var value        = CreateUUId();
				var recordId     = CreateUUId();
				var objectName   = "blah" & CreateUUId();
				var propertyName = "fubar" & CreateUUId();
				var renderer     = CreateUUId();
				var rendered     = CreateUUId();

				service.$( "getRendererForField" ).$args( objectName=objectName, propertyName=propertyname ).$results( renderer );
				mockContentRenderer.$( "render" ).$args(
					  renderer = renderer
					, data     = value
					, context  = [ "adminview", "admin" ]
					, args     = { objectName=objectName, propertyName=propertyName, recordId=recordId }
				).$results( rendered );

				expect( service.renderField(
					  recordId     = recordId
					, objectName   = objectName
					, propertyName = propertyName
					, value        = value
				) ).toBe( rendered );
			} );
		} );

		describe( "listRenderableObjectProperties()", function(){
			it( "should return an array of property names for an object sorted by sort order and excluding those whose admin renderer is 'none'", function(){
				var service    = _getService();
				var objectName = "someObject" & CreateUUId();
				var props      = StructNew( "linked" );

				props[ "propx"   ] = { sortorder=10  };
				props[ "propy"   ] = { sortorder=5   };
				props[ "propz"   ] = { sortorder=100 };
				props[ "test"    ] = {};
				props[ "testify" ] = { sortorder=39  };

				mockPoService.$( "getObjectProperties" ).$args( objectName=objectName ).$results( props );
				service.$( "getRendererForField" ).$args( objectName=objectName, propertyName="propx" ).$results( "none" );
				service.$( "getRendererForField", "testRenderer" );

				expect( service.listRenderableObjectProperties( objectName ) ).toBe( [
					  "propy"
					, "testify"
					, "propz"
					, "test"
				] );
			} );
		} );

		describe( "getDefaultViewGroupForProperty()", function(){
			it( "should return 'system' for system properties (datecreated, etc.)", function(){
				var service    = _getService();
				var objectName = "testObject" & CreateUUId();

				mockPoService.$( "getIdField"           ).$args( objectName ).$results( "__id"           );
				mockPoService.$( "getDateCreatedField"  ).$args( objectName ).$results( "__datecreated"  );
				mockPoService.$( "getDateModifiedField" ).$args( objectName ).$results( "__datemodified" );

				expect( service.getDefaultViewGroupForProperty( objectName, "__id"           ) ).toBe( "system" );
				expect( service.getDefaultViewGroupForProperty( objectName, "__datecreated"  ) ).toBe( "system" );
				expect( service.getDefaultViewGroupForProperty( objectName, "__datemodified" ) ).toBe( "system" );
			} );

			it( "should return 'default' for all other fields", function(){
				var service    = _getService();
				var objectName = "testObject" & CreateUUId();

				mockPoService.$( "getIdField"           ).$args( objectName ).$results( "id"           );
				mockPoService.$( "getDateCreatedField"  ).$args( objectName ).$results( "datecreated"  );
				mockPoService.$( "getDateModifiedField" ).$args( objectName ).$results( "datemodified" );
				mockPoService.$( "getObjectPropertyAttribute", "" );

				expect( service.getDefaultViewGroupForProperty( objectName, "somefield" ) ).toBe( "default" );
			} );
		} );

		describe( "getViewGroupForProperty()", function(){
			it( "should return the group defined on the property using the 'adminViewGroup' attribute", function(){
				var service      = _getService();
				var objectName   = "testobjectName"   & CreateUUId();
				var propertyName = "testpropertyName" & CreateUUId();
				var groupName    = "testdefaultGroup" & CreateUUId();

				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName   = objectName
					, propertyName = propertyName
					, attributeName = "adminViewGroup"
				).$results( groupName );

				expect( service.getViewGroupForProperty( objectName, propertyName ) ).toBe( groupName );
			} );

			it( "should return default group if property does not define its own", function(){
				var service      = _getService();
				var objectName   = "testobjectName"   & CreateUUId();
				var propertyName = "testpropertyName" & CreateUUId();
				var defaultGroup = "testdefaultGroup" & CreateUUId();

				mockPoService.$( "getObjectPropertyAttribute", "" );
				service.$( "getDefaultViewGroupForProperty" ).$args(
					  objectName   = objectName
					, propertyName = propertyName
				).$results( defaultGroup );

				expect( service.getViewGroupForProperty( objectName, propertyName ) ).toBe( defaultGroup );
			} );
		} );

		describe( "getViewGroupDetail()", function(){
			it( "should read view group details from the preside object properties file", function(){
				var service     = _getService();
				var objectName  = "testObject" & CreateUUId();
				var groupName   = "testGroup"  & CreateUUId();
				var rootUri     = "testuri"    & CreateUUId();
				var groupDetail = {
					  id          = groupName
					, title       = "Test group"
					, description = "Test group description"
					, iconClass   = "fa-test-icon"
					, sortorder   = 49
					, column      = "left"
				};

				mockPoService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( rootUri );

				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.title"      , defaultValue=groupName ).$results( groupDetail.title       );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.description", defaultValue=""        ).$results( groupDetail.description );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.iconClass"  , defaultValue=""        ).$results( groupDetail.iconClass   );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.sortOrder"  , defaultValue=1000      ).$results( groupDetail.sortOrder   );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.column"     , defaultValue="left"    ).$results( groupDetail.column      );

				expect( service.getViewGroupDetail(
					  objectName = objectName
					, groupName  = groupName
				) ).toBe( groupDetail );
			} );

			it( "should use special defaults when the group is 'default'", function(){
				var service     = _getService();
				var groupName   = "default";
				var objectName  = "testObject"   & CreateUUId();
				var objectDesc  = "yadda yadda"  & CreateUUId();
				var objectIcon  = "fa-icon-"     & CreateUUId();
				var objectTitle = "Test Object " & CreateUUId();
				var rootUri     = "testuri"      & CreateUUId();
				var groupDetail = {
					  id          = groupName
					, title       = "Test group"
					, description = "Test group description"
					, iconClass   = "fa-test-icon"
					, sortorder   = 49
					, column      = "left"
				};

				mockPoService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( rootUri );

				service.$( "$translateResource" ).$args( uri=rootUri & "title.singular", defaultValue=objectName ).$results( objectTitle );
				service.$( "$translateResource" ).$args( uri=rootUri & "description"   , defaultValue=""         ).$results( objectDesc );
				service.$( "$translateResource" ).$args( uri=rootUri & "iconClass"     , defaultValue=""         ).$results( objectIcon );

				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.title"      , defaultValue=objectTitle ).$results( groupDetail.title       );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.description", defaultValue=objectDesc  ).$results( groupDetail.description );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.iconClass"  , defaultValue=objectIcon  ).$results( groupDetail.iconClass   );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.sortOrder"  , defaultValue="1"         ).$results( groupDetail.sortOrder   );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.column"     , defaultValue="left"      ).$results( groupDetail.column      );

				expect( service.getViewGroupDetail(
					  objectName = objectName
					, groupName  = groupName
				) ).toBe( groupDetail );
			} );

			it( "should use special defaults when the group is 'system'", function(){
				var service     = _getService();
				var groupName   = "system";
				var objectName  = "testObject"   & CreateUUId();
				var objectDesc  = "yadda yadda"  & CreateUUId();
				var objectIcon  = "fa-icon-"     & CreateUUId();
				var objectTitle = "Test Object " & CreateUUId();
				var rootUri     = "testuri"      & CreateUUId();
				var groupDetail = {
					  id          = groupName
					, title       = "Test group"
					, description = "Test group description"
					, iconClass   = "fa-test-icon"
					, sortorder   = 49
					, column      = "right"
				};

				mockPoService.$( "getResourceBundleUriRoot" ).$args( objectName ).$results( rootUri );

				service.$( "$translateResource" ).$args( uri="cms:admin.view.system.group.title"      , defaultValue=groupName ).$results( objectTitle );
				service.$( "$translateResource" ).$args( uri="cms:admin.view.system.group.description", defaultValue=""        ).$results( objectDesc );
				service.$( "$translateResource" ).$args( uri="cms:admin.view.system.group.iconclass"  , defaultValue=""        ).$results( objectIcon );

				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.title"      , defaultValue=objectTitle ).$results( groupDetail.title       );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.description", defaultValue=objectDesc  ).$results( groupDetail.description );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.iconClass"  , defaultValue=objectIcon  ).$results( groupDetail.iconClass   );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.sortOrder"  , defaultValue="1"         ).$results( groupDetail.sortOrder   );
				service.$( "$translateResource" ).$args( uri=rootUri & "viewgroup.#groupName#.column"     , defaultValue="right"     ).$results( groupDetail.column      );

				expect( service.getViewGroupDetail(
					  objectName = objectName
					, groupName  = groupName
				) ).toBe( groupDetail );
			} );
		} );

		describe( "listViewGroupsForObject()", function(){
			it( "should return an array of view groups configured for the object's properties, ordered by column + group sort order / group title", function(){
				var service    = _getService();
				var objectName = "test_object_" & CreateUUId();
				var props      = [ "prop1", "prop2", "prop3", "prop4", "prop5", "prop6", "prop7" ];
				var groups     = {
					  system  = { blah="blah", test=CreateUUId(), title="System" , sortOrder=300, column="left" }
					, default = { blah="blah", test=CreateUUId(), title="Default", sortOrder=100, column="left" }
					, group1  = { blah="blah", test=CreateUUId(), title="Group 1", sortOrder=300, column="left" }
					, group5  = { blah="blah", test=CreateUUId(), title="Group 1", sortOrder=300, column="right" }
				};
				var expectedGroups = { left=[], right=[] };

				expectedGroups.left.append( duplicate( groups.default ) );
				expectedGroups.left.append( duplicate( groups.group1 ) );
				expectedGroups.left.append( duplicate( groups.system ) );
				expectedGroups.left[ 1 ].properties = [ props[ 2 ] ];
				expectedGroups.left[ 2 ].properties = [ props[ 1 ], props[ 4 ], props[ 5 ] ];
				expectedGroups.left[ 3 ].properties = [ props[ 3 ], props[ 6 ] ];
				expectedGroups.right.append( duplicate( groups.group5 ) );
				expectedGroups.right[ 1 ].properties = [ props[ 7 ] ];

				service.$( "listRenderableObjectProperties" ).$args( objectName ).$results( props );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 1 ] ).$results( "group1"  );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 2 ] ).$results( "default" );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 3 ] ).$results( "system"  );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 4 ] ).$results( "group1"  );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 5 ] ).$results( "group1"  );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 6 ] ).$results( "system"  );
				service.$( "getViewGroupForProperty" ).$args( objectName, props[ 7 ] ).$results( "group5"  );
				for( var groupName in groups ) {
					service.$( "getViewGroupDetail" ).$args( objectName, groupName ).$results( groups[ groupName ] );
				}

				expect( service.listViewGroupsForObject( objectName ) ).toBe( expectedGroups );
			} );
		} );

		describe( "listGridFieldsForRelationshipPropertyTable()", function(){
			it( "should return grid fields based on @minimalGridFields property defined on the related object", function(){
				var service           = _getService();
				var objectName        = "test_object"   & CreateUUId();
				var relatedObjectName = "related_object" & CreateUUId();
				var propertyName      = "property_name" & CreateUUId();
				var relatedGridFields = "label,category.label as category,category$parent.label as parentCategory";
				var expectedFields    = [ "label", "category.label as category", "category$parent.label as parentCategory" ];


				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = propertyName
					, attributeName = "relatedTo"
				).$results( relatedObjectName );

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "minimalGridFields"
				).$results( relatedGridFields );

				expect( service.listGridFieldsForRelationshipPropertyTable(
					  objectName   = objectName
					, propertyName = propertyName
				) ).toBe( expectedFields );

			} );

			it( "should return grid fields based on @gridFields property defined on the related object, should the object not supply @minimalGridFields", function(){
				var service           = _getService();
				var objectName        = "test_object"   & CreateUUId();
				var relatedObjectName = "related_object" & CreateUUId();
				var propertyName      = "property_name" & CreateUUId();
				var relatedGridFields = "label,category.label as category,category$parent.label as parentCategory";
				var expectedFields    = [ "label", "category.label as category", "category$parent.label as parentCategory" ];


				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = propertyName
					, attributeName = "relatedTo"
				).$results( relatedObjectName );

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "minimalGridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "gridFields"
				).$results( relatedGridFields );

				expect( service.listGridFieldsForRelationshipPropertyTable(
					  objectName   = objectName
					, propertyName = propertyName
				) ).toBe( expectedFields );
			} );

			it( "should return grid fields based on @datamanagerGridFields property defined on the related object, should the object not supply @minimalGridFields or @gridFields", function(){
				var service           = _getService();
				var objectName        = "test_object"   & CreateUUId();
				var relatedObjectName = "related_object" & CreateUUId();
				var propertyName      = "property_name" & CreateUUId();
				var relatedGridFields = "label,category.label as category,category$parent.label as parentCategory";
				var expectedFields    = [ "label", "category.label as category", "category$parent.label as parentCategory" ];


				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = propertyName
					, attributeName = "relatedTo"
				).$results( relatedObjectName );

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "minimalGridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "gridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "datamanagerGridFields"
				).$results( relatedGridFields );

				expect( service.listGridFieldsForRelationshipPropertyTable(
					  objectName   = objectName
					, propertyName = propertyName
				) ).toBe( expectedFields );
			} );

			it( "should return labelfield + datemodified when the related object does not define any grid fields", function(){
				var service           = _getService();
				var objectName        = "test_object"   & CreateUUId();
				var relatedObjectName = "related_object" & CreateUUId();
				var propertyName      = "property_name" & CreateUUId();
				var expectedFields    = [ "mylabelfield" ];


				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = propertyName
					, attributeName = "relatedTo"
				).$results( relatedObjectName );

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "minimalGridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "gridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "datamanagerGridFields"
				).$results( "" );

				mockPoService.$( "getLabelField" ).$args( relatedObjectName ).$results( "mylabelfield" );

				expect( service.listGridFieldsForRelationshipPropertyTable(
					  objectName   = objectName
					, propertyName = propertyName
				) ).toBe( expectedFields );
			} );

			it( "should return idFIeld + datemodified when the related object does not have a label field", function(){
				var service           = _getService();
				var objectName        = "test_object"   & CreateUUId();
				var relatedObjectName = "related_object" & CreateUUId();
				var propertyName      = "property_name" & CreateUUId();
				var expectedFields    = [ "myidfield" ];


				mockPoService.$( "getObjectPropertyAttribute" ).$args(
					  objectName    = objectName
					, propertyName  = propertyName
					, attributeName = "relatedTo"
				).$results( relatedObjectName );

				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "minimalGridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "gridFields"
				).$results( "" );
				mockPoService.$( "getObjectAttribute" ).$args(
					  objectName    = relatedObjectName
					, attributeName = "datamanagerGridFields"
				).$results( "" );

				mockPoService.$( "getLabelField" ).$args( relatedObjectName ).$results( "" );
				mockPoService.$( "getIdField" ).$args( relatedObjectName ).$results( "myidfield" );

				expect( service.listGridFieldsForRelationshipPropertyTable(
					  objectName   = objectName
					, propertyName = propertyName
				) ).toBe( expectedFields );
			} );
		} );
	}

// HELPERS
	private any function _getService() {
		mockContentRenderer      = CreateEmptyMock( "preside.system.services.rendering.ContentRendererService" );
		mockPoService            = CreateEmptyMock( "preside.system.services.presideObjects.PresideObjectService" );
		mockDataManagerService   = CreateEmptyMock( "preside.system.services.admin.DataManagerService" );
		mockColdbox              = CreateStub();

		var service = CreateMock( object=new preside.system.services.admin.AdminDataViewsService(
			  contentRendererService = mockContentRenderer
			, dataManagerService     = mockDataManagerService
		) );

		service.$( "$getPresideObjectService", mockPoService );
		service.$( "$getColdbox", mockColdbox );
		service.$( "$getI18nLocale", "en-UK" );

		return service;
	}

}