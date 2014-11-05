component output=false singleton=true {

// CONSTRUCTOR
	/**
	 * @objectReader.inject PresideObjectReader
	 */
	public any function init( required any objectReader ) output=false {
		_setObjectReader( arguments.objectReader );

		return this;
	}

// PUBLIC API METHODS
	public array function calculateJoins( required string objectName, required array joinTargets, string forceJoins ) output=false {
		// TODO, MAKE THIS ENTIRE METHOD UNDERSTANDABLE! (refactor now that tests are in place)

		var relationships   = _getRelationships();
		var relationship    = "";
		var relatedObj            = "";
		var columnJoins           = [];
		var joins                 = [];
		var join                  = "";
		var joinCount             = "";
		var discoveredJoins       = {};
		var discoveredColumnJoins = {};
		var lookupQueue           = [ [ arguments.objectName ] ];
		var lookupObj             = "";
		var target                = "";
		var backTrace             = {};
		var backTraceFilled       = "";
		var backtraceNode         = "";
		var i                     = 0;
		var n                     = 0;

		for( target in arguments.joinTargets ){
			columnJoins = _calculateColumnJoins( objectName, target, joins, arguments.forceJoins ?: "" );

			if ( ArrayLen( columnJoins ) ) {
				discoveredJoins[ target ] = 1;
				discoveredColumnJoins[ target ] = 1;

				for( join in columnJoins ) {
					if ( !_joinExists( join, joins ) ) {
						discoveredColumnJoins[ join.tableAlias ?: join.joinToObject ] = 1;
						ArrayAppend( joins, join );
					}
				}
			}
		}

		while( i lt ArrayLen( lookupQueue ) and StructCount( discoveredJoins ) lt ArrayLen( joinTargets ) ){
			i++;


			for( n=1; n lte ArrayLen( lookupQueue[ i ] ); n++ ){
				lookupObj = lookupQueue[ i ][ n ];

				if ( StructKeyExists( relationships, lookupObj ) ) {
					if ( ArrayLen( lookupQueue ) lt i+1 ){
						ArrayAppend( lookupQueue, [] );
					}
					for( relatedObj in relationships[ lookupObj ]  ){
						if ( StructKeyExists( backTrace, lookupObj ) and backTrace[ lookupObj ].parent eq relatedObj ) {
							continue;
						}

						if ( not StructKeyExists( backTrace, relatedObj ) ) {
							ArrayAppend( lookupQueue[i+1], relatedObj );
							backTrace[ relatedObj ] = { name=relatedObj, parent=lookupObj, relationship=relationships[ lookupObj ][ relatedObj ][1] };
						}

						if ( not ListFindNoCase( ArrayToList( joinTargets ), relatedObj ) ) {
							continue;
						}
						if ( not StructKeyExists( discoveredColumnJoins, relatedObj ) and ( StructKeyExists( discoveredJoins, relatedObj ) or ArrayLen( relationships[ lookupObj ][ relatedObj ] ) gt 1 ) ) {
							throw(
								  type    = "RelationshipGuidance.RelationshipTooComplex"
								, message = "Relationship between [#arguments.objectName#] and [#relatedObj#] could not be automatically created because there are multiple relationship paths between the objects"
								, detail  = "The Relationship Guidance service will only attempt to automatically calculate joins where there is a single path between the nodes"
							);
						}

						backTraceFilled = false;
						backtraceNode = backTrace[ relatedObj ];
						joinCount = ArrayLen( joins );

						while( not backTraceFilled ) {
							discoveredJoins[ backtraceNode.name ] = 1;
							relationship = backtraceNode.relationship;
							join = {
								  type           = ( Len( Trim ( arguments.forceJoins ?: "" ) ) ? arguments.forceJoins : ( relationship.required ? 'inner' : 'left' ) )
								, joinToObject   = backtraceNode.name
								, joinFromObject = backtraceNode.parent
								, joinFromAlias  = backtraceNode.parent
							};

							switch( relationship.type ) {
								case "many-to-one":
									join.joinFromProperty = relationship.fk;
									join.joinToProperty   = relationship.pk;
								break;
								case "one-to-many":
									join.joinFromProperty = relationship.pk;
									join.joinToProperty   = relationship.fk;
								break;
							}

							if ( !_joinExists( join, joins ) ) {
								if ( joinCount gte ArrayLen( joins ) ) {
									ArrayAppend( joins, join );
								} else {
									ArrayInsertAt( joins, joinCount+1, join );
								}
							}



							if ( backtraceNode.parent eq arguments.objectName or ListFindNoCase( ArrayToList( joinTargets ), backtraceNode.parent ) ) {
								backTraceFilled = true;
							} else {
								ArrayAppend( joinTargets, backtraceNode.parent );
								backtraceNode = backtrace[ backtraceNode.parent ];
							}
						}

					}
				}
			}

		}

		for( target in arguments.joinTargets ) {
			if ( not StructKeyExists( discoveredJoins, target ) ) {
				throw(
					  type    = "RelationshipGuidance.RelationshipTooComplex"
					, message = "Relationship between [#arguments.objectName#] and [#target#] could not be calculated because no path exists"
					, detail  = "The Relationship Guidance service will only attempt to automatically calculate joins where there is a single path between the nodes"
				);
			}
		}


		return joins;
	}

	public void function setupRelationships( required struct objects ) output=false {
		var object           = "";
		var objectName       = "";
		var objectNames      = StructKeyArray( arguments.objects );
		var property         = "";
		var keyName          = "";
		var relationships    = {};
		var m2mRelationships = {};
		var autoObjects      = {};
		var autoObject       = "";
		var i                = "";

		// !!! IMPORTANT TO LOOP THIS WAY (so that auto generated objects for many-to-many relationships can be processed by being pushed on to the array )
		for( i=1; i lte ArrayLen( objectNames ); i++ ) {
			objectName = objectNames[ i ];
			object = objects[ objectName ];

			for( var propertyName in object.meta.properties ) {
				property = object.meta.properties[ propertyName ];

				if ( property.relationship EQ "many-to-many" ) {
					if ( StructKeyExists( property, "relatedVia" ) and Len( Trim( property.relatedVia ) ) ) {
						continue;
					}

					if ( not StructKeyExists( objects, property.relatedTo ) ) {
						throw(
							  type    = "RelationshipGuidance.BadRelationship"
							, message = "Object, [#property.relatedTo#], could not be found"
							, detail  = "The property, [#propertyName#], in Preside component, [#objectName#], declared a [#property.relationship#] relationship with the object [#property.relatedTo#]; this object could not be found."
						);
					}
					autoObject = _getObjectReader().getAutoPivotObjectDefinition(
						  objectA = object.meta
						, objectB = objects[ property.relatedTo ].meta
					);
					property.relatedVia = autoObject.name;

					if ( not StructKeyExists( objects, autoObject.name ) ) {
						objects[ autoObject.name ] = {
							  meta     = autoObject
							, instance = "auto_generated"
						};
						ArrayAppend( objectNames, autoObject.name );
					}

					if ( not StructKeyExists( m2mRelationships, objectName ) ) {
						m2mRelationships[ objectName ] = {};
					}
					if ( not StructKeyExists( m2mRelationships[objectName], property.relatedTo ) ) {
						m2mRelationships[ objectName ][ property.relatedTo ] = [];
					}
					ArrayAppend( m2mRelationships[ objectName ][ property.relatedTo ], {
						  type         = "many-to-many"
						, required     = property.required
						, pivotObject  = autoObject.name
						, propertyName = propertyName
					} );

				} else if ( property.relationship EQ "many-to-one" ) {

					if ( not StructKeyExists( objects, property.relatedto ) ) {
						throw(
							  type    = "RelationshipGuidance.BadRelationship"
							, message = "Object, [#property.relatedTo#], could not be found"
							, detail  = "The property, [#propertyName#], in Preside component, [#objectName#], declared a [#property.relationship#] relationship with the object [#property.relatedTo#]; this object could not be found."
						);
					}

					if ( not property.attributeExists( "onDelete" ) ){
						property.setAttribute( "onDelete", ( property.required ? "error" : "set null" ) );
					}
					if ( not property.attributeExists( "onUpdate" ) ){
						property.setAttribute( "onUpdate", "cascade" );
					}

					keyName = "fk_#Hash( property.relatedto & objectName & propertyName )#";

					if ( not StructKeyExists( object.meta, "relationships" ) ) {
						object.meta.relationships = {};
					}

					object.meta.relationships[ keyName ] = {
						  pk_table  = objects[ property.relatedto ].meta.tableName
						, fk_table  = object.meta.tableName
						, pk_column = "id"
						, fk_column = propertyName
						, on_update = property.onUpdate
						, on_delete = property.onDelete
					};

					if ( not StructKeyExists( relationships, objectName ) ) {
						relationships[ objectName ] = {};
					}
					if ( not StructKeyExists( relationships[objectName], property.relatedTo ) ) {
						relationships[ objectName ][ property.relatedTo ] = [];
					}
					ArrayAppend( relationships[ objectName ][ property.relatedTo ], {
						  type      = "many-to-one"
						, required  = property.required
						, pk        = "id"
						, fk        = propertyName
						, onUpdate  = property.onUpdate
						, onDelete  = property.onDelete
					} );

					if ( not StructKeyExists( relationships, property.relatedTo ) ) {
						relationships[ property.relatedto ] = {};
					}
					if ( not StructKeyExists( relationships[property.relatedTo], objectName ) ) {
						relationships[ property.relatedTo ][ objectName ] = [];
					}
					ArrayAppend( relationships[ property.relatedTo ][ objectName ], {
						  type     = "one-to-many"
						, required = property.required
						, pk       = "id"
						, fk       = propertyName
						, onUpdate = property.onUpdate
						, onDelete = property.onDelete
					} );

					property.setAttribute( "type"     , objects[ property.relatedto ].meta.properties.id.type      );
					property.setAttribute( "dbType"   , objects[ property.relatedto ].meta.properties.id.dbType    );
					property.setAttribute( "maxLength", objects[ property.relatedto ].meta.properties.id.maxLength );
				}
			}
		}

		_setRelationships( relationships );
		_setManyToManyRelationships( m2mRelationships );
	}

	public struct function getObjectRelationships( required string objectName ) output=false {
		var relationships = _getRelationships();

		if ( StructKeyExists( relationships, arguments.objectName ) ) {
			return relationships[ arguments.objectName ];
		}

		return {};
	}

// PRIVATE HELPERS
	private array function _calculateColumnJoins(
		  required string objectName
		, required string target
		, required array  existingJoins
		, required string forceJoins

	) output=false {
		var currentSource = arguments.objectName;
		var targetPos     = 0;
		var joins         = [];
		var joinAlias     = "";
		var currentAlias  = "";

		while( targetPos lt ListLen( target, "$" ) ) {
			var targetCol    = ListGetAt( target, ++targetPos, "$" );
			var relationship = _findColumnRelationship( currentSource, targetCol );

			if ( not StructCount( relationship ) ) {
				return [];
			}

			if ( relationship.type eq "many-to-many" ) {
				ArrayAppend( joins, {
					  type               = ( Len( Trim ( arguments.forceJoins ) ) ? arguments.forceJoins : ( relationship.required ? 'inner' : 'left' ) )
					, joinToObject       = relationship.pivotObject
					, joinFromObject     = currentSource
					, joinFromAlias      = currentSource
					, joinFromProperty   = "id"
					, joinToProperty     = currentSource
					, manyToManyProperty = relationship.propertyName
				} );
			}

			joinAlias = ListAppend( joinAlias, targetCol, "$" );
			var join = {
				  type             = ( Len( Trim ( arguments.forceJoins ) ) ? arguments.forceJoins : ( relationship.required ? 'inner' : 'left' ) )
				, joinToObject     = relationship.type eq "many-to-many" ? relationship.object      : relationship.object
				, joinFromObject   = relationship.type eq "many-to-many" ? relationship.pivotObject : currentSource
				, joinFromAlias    = Len( Trim( currentAlias ) ) ? currentAlias : ( relationship.type eq "many-to-many" ? relationship.pivotObject : currentSource )
				, joinFromProperty = relationship.type eq "many-to-many" ? relationship.object      : relationship.fk
				, joinToProperty   = relationship.type eq "many-to-many" ? "id"                     : relationship.pk
			};
			currentSource = relationship.object;
			currentAlias  = joinAlias;

			if ( joinAlias neq relationship.object ) {
				join.tableAlias = joinAlias;
			}

			ArrayAppend( joins, join );
		}

		return joins;
	}

	private struct function _findColumnRelationship( required string objectName, required string columnName ) output=false {
		var found = {};
		var relationships = _getRelationships();
		relationships = relationships[ arguments.objectName ] ?: {};

		for( var foreignObj in relationships ){
			for( var join in relationships[ foreignObj ] ) {
				if ( join.type eq "many-to-one" and join.fk eq arguments.columnName ) {
					found = Duplicate( join );
					found.object = foreignObj;
					return found;
				}
			}
		}

		relationships = _getManyToManyRelationships();
		relationships = relationships[ arguments.objectName ] ?: {};
		for( var foreignObj in relationships ){
			for( var join in relationships[ foreignObj ] ) {
				if ( join.propertyName eq arguments.columnName ) {
					found = Duplicate( join );
					found.object = foreignObj;
					return found;
				}
			}
		}

		return {};
	}

	private boolean function _joinExists( required struct join, required array joins ) output=false {
		var cleanedJoin    = Duplicate( join );
		var serializedJoin = "";

		StructDelete( cleanedJoin, "manyToManyProperty" );
		serializedJoin = SerializeJson( cleanedJoin );

		for( var existingJoin in arguments.joins ) {
			cleanedJoin = Duplicate( existingJoin );
			StructDelete( cleanedJoin, "manyToManyProperty" );

			if ( SerializeJson( cleanedJoin ) eq serializedJoin ) {
				return true;
			}
		}

		return false;
	}

// GETTERS AND SETTERS
	private any function _getObjectReader() output=false {
		return _objectReader;
	}
	private void function _setObjectReader( required any objectReader ) output=false {
		_objectReader = arguments.objectReader;
	}

	private any function _getRelationships() output=false {
		return _relationships;
	}
	private void function _setRelationships( required any relationships ) output=false {
		_relationships = arguments.relationships;
	}

	private any function _getManyToManyRelationships() output=false {
		return _manyToManyRelationships;
	}
	private void function _setManyToManyRelationships( required any manyToManyRelationships ) output=false {
		_manyToManyRelationships = arguments.manyToManyRelationships;
	}
}