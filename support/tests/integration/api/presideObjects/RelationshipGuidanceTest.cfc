<cfcomponent output="false" extends="tests.resources.HelperObjects.PresideTestCase">

	<cffunction name="test01_calculateJoins_shouldAutomaticallyCalculateSimpleManyToOneRelationship" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_a"
				, type             = "inner"
			}];
			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { obj_a  = { relationship="many-to-one", relatedTo="obj_a", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_b"
				, joinTargets   = [ "obj_a" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test02_calculateJoins_shouldAutomaticallyCalculateSimpleOneToManyRelationship" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject     = "obj_b"
				, joinToProperty   = "obj_a"
				, joinFromObject   = "obj_a"
				, joinFromProperty = "id"
				, type             = "inner"
			}];
			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { obj_a  = { relationship="many-to-one", relatedTo="obj_a", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_a"
				, joinTargets   = [ "obj_b" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test03_calculateJoins_shouldThrowInformativeError_whenCannotAutoCalculateSimpleJoin" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var errorThrown     = false;
			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_c.meta = { tableName="pobj_obj_c", properties = _getProperties( { obj_b  = { relationship="many-to-one", relatedTo="obj_b", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			try {
				result = guidanceService.calculateJoins(
					  objectName    = "obj_c"
					, joinTargets   = [ "obj_a" ]
				);
			} catch( "RelationshipGuidance.RelationshipTooComplex" e ){
				super.assertEquals( "Relationship between [obj_c] and [obj_a] could not be calculated because no path exists", e.message );
				super.assertEquals( "The Relationship Guidance service will only attempt to automatically calculate joins where there is a single path between the nodes", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "No informative error was thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test04_calculateJoins_shouldThrowInformativeError_whenCannotAutoCalculateJoinsBecauseOfMultiple" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var errorThrown     = false;
			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { obj_a_col = { relationship="many-to-one", relatedTo="obj_a", required=true }, obj_a_secondary = { relationship="many-to-one", relatedTo="obj_a", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			try {
				result = guidanceService.calculateJoins(
					  objectName    = "obj_b"
					, joinTargets   = [ "obj_a" ]
				);
			} catch( "RelationshipGuidance.RelationshipTooComplex" e ){
				super.assertEquals( "Relationship between [obj_b] and [obj_a] could not be automatically created because there are multiple relationship paths between the objects", e.message );
				super.assertEquals( "The Relationship Guidance service will only attempt to automatically calculate joins where there is a single path between the nodes", e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "No informative error was thrown" );
		</cfscript>
	</cffunction>

	<cffunction name="test05_calculateJoins_shouldBeAbleToAutomaticallyCalculateJoinsInASimpleChain_whenAllObjectsInTheChainAreSuppliedAsTargets" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject     = "obj_b"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_c"
				, joinFromProperty = "obj_b"
				, type             = "inner"
			},{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_a"
				, type             = "inner"
			}];

			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_a = { relationship="many-to-one", relatedTo="obj_a", required=true } } ) }
				, obj_c.meta = { tableName="pobj_obj_c", properties = _getProperties( { obj_b  = { relationship="many-to-one", relatedTo="obj_b", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_c"
				, joinTargets   = [ "obj_a", "obj_b" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test06_calculateJoins_shouldBeAbleToAutomaticallyCalculateJoinsInASimpleChain_evenWhenNotAllObjectsInTheChainAreSuppliedAsTargets" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject     = "obj_b"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_c"
				, joinFromProperty = "obj_b"
				, type             = "left"
			},{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_a"
				, type             = "inner"
			}];

			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_a = { relationship="many-to-one", relatedTo="obj_a", required=true } } ) }
				, obj_c.meta = { tableName="pobj_obj_c", properties = _getProperties( { obj_b  = { relationship="many-to-one", relatedTo="obj_b", required=false } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_c"
				, joinTargets   = [ "obj_a" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test07_calculateJoins_shouldBeAbleToAutomaticallyCalculateMultipleJoinsInAMoreComplexChain" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject     = "obj_b"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_c"
				, joinFromProperty = "obj_b"
				, type             = "inner"
			},{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_a"
				, type             = "inner"
			},{
				  joinToObject     = "obj_d"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_d"
				, type             = "inner"
			},{
				  joinToObject     = "obj_e"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_d"
				, joinFromProperty = "obj_e"
				, type             = "inner"
			}];

			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_a = { relationship="many-to-one", relatedTo="obj_a", required=true }, obj_d = { relationship="many-to-one", relatedTo="obj_d", required=true } } ) }
				, obj_c.meta = { tableName="pobj_obj_c", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_b  = { relationship="many-to-one", relatedTo="obj_b", required=true } } ) }
				, obj_d.meta = { tableName="pobj_obj_d", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_e = { relationship="many-to-one", relatedTo="obj_e", required=true } } ) }
				, obj_e.meta = { tableName="pobj_obj_e", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_f.meta = { tableName="pobj_obj_f", properties = _getProperties( { obj_c  = { relationship="many-to-one", relatedTo="obj_c", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_c"
				, joinTargets   = [ "obj_a", "obj_e" ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test08_calculateJoins_shouldAlwaysUseInnerJoins_whenForceJoinsIsSetToInner" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject     = "obj_b"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_c"
				, joinFromProperty = "obj_b"
				, type             = "inner"
			},{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_a"
				, type             = "inner"
			}];

			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_a = { relationship="many-to-one", relatedTo="obj_a", required=false } } ) }
				, obj_c.meta = { tableName="pobj_obj_c", properties = _getProperties( { obj_b  = { relationship="many-to-one", relatedTo="obj_b", required=false } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_c"
				, joinTargets   = [ "obj_a" ]
				, forceJoins    = "inner"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test09_setupRelationships_shouldCreatePseudoObjectForManyToManyRelationshipsThatDoNotDeclareAPivotObject" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var objects = {
				  obj_a.meta = { dsn="test", name="some.path.to.obj_a", tableName="pobj_obj_a", tablePrefix="pobj_", properties = { id = { type="numeric", relationship="none", dbtype="smallint", maxLength=0, label="some id" } } }
				, obj_b.meta = { dsn="test", name="some.path.to.obj_b", tableName="pobj_obj_b", tablePrefix="pobj_", properties = { id = { type="string" , relationship="none", dbtype="varchar", maxLength=35, label="another id" }, obj_a = { relationship="many-to-many", relatedTo="obj_a", required=false } } }
			};
			var expectedObject = {
				  instance = "auto_generated"
				, meta = {
					  dbFieldList = "obj_a,obj_b,sort_order"
					, dsn         = "test"
					, indexes     = { ux_obj_a__join__obj_b = { unique="true", fields="obj_a,obj_b" } }
					, name        = "obj_a__join__obj_b"
					, tableName   = "pobj_obj_a__join__obj_b"
					, tablePrefix = "pobj_"
					, versioned   = false
					, properties  = {
						  obj_a = { name="obj_a", control="auto", type="numeric", dbtype="smallint", maxLength="0" , generator="none", relationship="many-to-one", relatedTo="obj_a", required=true, onDelete="cascade", onUpdate="cascade" }
						, obj_b = { name="obj_b", control="auto", type="string" , dbtype="varchar" , maxLength="35", generator="none", relationship="many-to-one", relatedTo="obj_b", required=true, onDelete="cascade", onUpdate="cascade" }
						, sort_order = { name="sort_order", control="auto", type="numeric" , dbtype="int" , maxLength="0", generator="none", relationship="none", required=false }
					  }
					, relationships = {
						  "fk_#Hash( 'obj_aobj_a__join__obj_bobj_a' )#" = { pk_table="pobj_obj_a", fk_table="pobj_obj_a__join__obj_b", pk_column="id", fk_column="obj_a", on_update="cascade", on_delete="cascade" }
						, "fk_#Hash( 'obj_bobj_a__join__obj_bobj_b' )#" = { pk_table="pobj_obj_b", fk_table="pobj_obj_a__join__obj_b", pk_column="id", fk_column="obj_b", on_update="cascade", on_delete="cascade" }
					  }
				  }
			};

			guidanceService.setupRelationships( objects );

			super.assert( StructKeyExists( objects, "obj_a__join__obj_b" ), "Pivot object was not automatically created" );
			objects[ "obj_a__join__obj_b" ].meta.properties = _propertiesToStruct( objects[ "obj_a__join__obj_b" ].meta.properties );
			super.assertEquals( expectedObject, objects[ "obj_a__join__obj_b" ] );
		</cfscript>
	</cffunction>

	<cffunction name="test10_calculateJoins_shouldBeAbleToCalculateJoinAcrossAutoManyToManyRelationship" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var result          = "";
			var expected        = [{
				  joinToObject       = "obj_a__join__obj_b"
				, joinToProperty     = "obj_b"
				, joinFromObject     = "obj_b"
				, joinFromProperty   = "id"
				, type               = "inner"
				, manyToManyProperty = "obj_a"
			},{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_a__join__obj_b"
				, joinFromProperty = "obj_a"
				, type             = "inner"
			}];
			var objects = {
				  obj_a.meta = { dsn="test", name="some.path.to.obj_a", tableName="pobj_obj_a", tablePrefix="pobj_", properties = { id = { type="numeric", relationship="none", dbtype="smallint", maxLength=0, label="some id" } } }
				, obj_b.meta = { dsn="test", name="some.path.to.obj_b", tableName="pobj_obj_b", tablePrefix="pobj_", properties = { id = { type="string" , relationship="none", dbtype="varchar", maxLength=35, label="another id" }, obj_a = { relationship="many-to-many", relatedTo="obj_a", required=false } } }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_b"
				, joinTargets   = [ "obj_a" ]
				, forceJoins    = "inner"
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

	<cffunction name="test11_setupRelationships_shouldThrowInformativeError_whenManyToManyRelationshipRefersToNonExistantObject" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var objects = {
				  obj_a.meta = { dsn="test", name="some.path.to.obj_a", tableName="pobj_obj_a", properties = { id = { type="numeric", relationship="none", dbtype="smallint", maxLength=0, label="some id" } } }
				, obj_b.meta = { dsn="test", name="some.path.to.obj_b", tableName="pobj_obj_b", properties = { id = { type="string" , relationship="none", dbtype="varchar", maxLength=35, label="another id" }, related_object_fs = { relationship="many-to-many", relatedTo="obj_f", required=false } } }
			};
			var errorThrown = false;
			var expectedMessage = "Object, [obj_f], could not be found";
			var expectedDetail  = "The property, [related_object_fs], in Preside component, [obj_b], declared a [many-to-many] relationship with the object [obj_f]; this object could not be found.";

			try{
				guidanceService.setupRelationships( objects );
			} catch( "RelationshipGuidance.BadRelationship" e ){
				super.assertEquals( expectedMessage, e.message );
				super.assertEquals( expectedDetail , e.detail );
				errorThrown = true;
			}

			super.assert( errorThrown, "An informative error was not thrown when a bad many-to-many relationship was defined" );
		</cfscript>
	</cffunction>

	<cffunction name="test12_setupRelationships_shouldNotCreateAutoPivotObject_whenPivotObjectIsDeclaredInRelationship" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var objects = {
				  obj_a.meta     = { dsn="test", name="some.path.to.obj_a"    , tableName="pobj_obj_a", properties = { id = { type="numeric", relationship="none", dbtype="smallint", maxLength=0, label="some id" } } }
				, obj_b.meta     = { dsn="test", name="some.path.to.obj_b"    , tableName="pobj_obj_b", properties = { id = { type="string" , relationship="none", dbtype="varchar", maxLength=35, label="another id" }, obj_a = { relationship="many-to-many", relatedTo="obj_a", relatedVia="pivot_obj", required=false } } }
				, pivot_obj.meta = { dsn="test", name="some.path.to.pivot_obj", tableName="pobj_pivot_obj", properties = { id = { type="string" , relationship="none", dbtype="varchar", maxLength=35, label="another id" } } }
			};

			guidanceService.setupRelationships( objects );

			super.assertFalse( StructKeyExists( objects, "obj_a__join__obj_b" ), "Pivot object was automatically created but should not have been due to 'relatedVia' property" );
		</cfscript>
	</cffunction>

	<cffunction name="test13_calculateJoins_shouldBeAbleToBaseComplexJoinsOnDottedColumnNames_ratherThanJustByTheFinalObjectName" returntype="void">
		<cfscript>
			var guidanceService = _getGuidanceService();
			var expected        = [{
				  joinToObject     = "obj_b"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_c"
				, joinFromProperty = "obj_b"
				, type             = "inner"
			},{
				  joinToObject     = "obj_d"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_d"
				, tableAlias       = "obj_b$obj_d"
				, type             = "inner"
			},{
				  joinToObject     = "obj_e"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_d"
				, joinFromProperty = "obj_e"
				, tableAlias       = "obj_b$obj_d$obj_e"
				, type             = "inner"
			},{
				  joinToObject     = "obj_b"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_c"
				, joinFromProperty = "obj_b_again"
				, tableAlias       = "obj_b_again"
				, type             = "inner"
			},{
				  joinToObject     = "obj_a"
				, joinToProperty   = "id"
				, joinFromObject   = "obj_b"
				, joinFromProperty = "obj_a"
				, tableAlias       = "obj_b_again$obj_a"
				, type             = "inner"
			}];

			var objects = {
				  obj_a.meta = { tableName="pobj_obj_a", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_b.meta = { tableName="pobj_obj_b", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_a = { relationship="many-to-one", relatedTo="obj_a", required=true }, obj_d = { relationship="many-to-one", relatedTo="obj_d", required=true } } ) }
				, obj_c.meta = { tableName="pobj_obj_c", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_b  = { relationship="many-to-one", relatedTo="obj_b", required=true }, obj_b_again  = { relationship="many-to-one", relatedTo="obj_b", required=true } } ) }
				, obj_d.meta = { tableName="pobj_obj_d", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 }, obj_e = { relationship="many-to-one", relatedTo="obj_e", required=true } } ) }
				, obj_e.meta = { tableName="pobj_obj_e", properties = _getProperties( { id = { relationship="none", type="string", dbtype="varchar", maxLength=35 } } ) }
				, obj_f.meta = { tableName="pobj_obj_f", properties = _getProperties( { obj_c  = { relationship="many-to-one", relatedTo="obj_c", required=true } } ) }
			};

			guidanceService.setupRelationships( objects );

			result = guidanceService.calculateJoins(
				  objectName    = "obj_c"
				, joinTargets   = [
					  "obj_b$obj_d$obj_e"
					, "obj_b_again$obj_a"
				  ]
			);

			super.assertEquals( expected, result );
		</cfscript>
	</cffunction>

<!--- private helpers --->
	<cffunction name="_getGuidanceService" access="private" returntype="any" output="false">
		<cfscript>
			var reader               = new preside.system.services.presideObjects.PresideObjectReader(
				  dsn                = "default_dsn"
				, tablePrefix        = "pobj_"
				, interceptorService = _getMockInterceptorService()
			);

			return new preside.system.services.presideObjects.RelationshipGuidance(
				objectReader  = reader
			);
		</cfscript>
	</cffunction>

	<cffunction name="_getProperties" access="private" returntype="struct" output="false">
		<cfargument name="rawProps" type="struct" required="true" />

		<cfscript>
			var newProps = {};
			for( var prop in rawProps ) {
				newProps[ prop ] = new preside.system.services.presideObjects.Property( argumentCollection=rawProps[prop] );
			}

			return newProps;
		</cfscript>
	</cffunction>

	<cffunction name="_propertiesToStruct" access="private" returntype="struct" output="false">
		<cfargument name="properties" type="struct" required="true" />

		<cfscript>
			var newProps = {};

			for( var key in arguments.properties ){
				newProps[ key ] = arguments.properties[ key ].getMemento();
			}

			return newProps;
		</cfscript>
	</cffunction>

</cfcomponent>