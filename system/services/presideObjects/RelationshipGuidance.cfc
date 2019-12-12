component singleton=true {

// CONSTRUCTOR
	/**
	 * @objectReader.inject          PresideObjectReader
	 * @selectDataViewService.inject presideObjectSelectDataViewService
	 */
	public any function init( required any objectReader, required any selectDataViewService ) {
		_setObjectReader( arguments.objectReader );
		_setSelectDataViewService( arguments.selectDataViewService );

		return this;
	}

// PUBLIC API METHODS
	public array function calculateJoins( required string objectName, required array joinTargets, string forceJoins ) {
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
						target = join.tableAlias ?: ( join.joinToObject ?: join.subQueryAlias );
						discoveredColumnJoins[ target ] = 1;
						if ( arguments.joinTargets.findNoCase( target ) ){
							discoveredJoins[ target ] = 1;
						}
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

	public void function setupRelationships( required struct objects ) {
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
		var pkMappings       = {};

		// !!! IMPORTANT TO LOOP THIS WAY (so that auto generated objects for many-to-many relationships can be processed by being pushed on to the array )
		for( i=1; i lte ArrayLen( objectNames ); i++ ) {
			objectName = objectNames[ i ];
			object = objects[ objectName ];

			for( var propertyName in object.meta.properties ) {
				property = object.meta.properties[ propertyName ];

				if ( property.relationship eq "many-to-many" ) {
					if ( !StructKeyExists( objects, property.relatedTo ) ) {
						throw(
							  type    = "RelationshipGuidance.BadRelationship"
							, message = "Object, [#property.relatedTo#], could not be found"
							, detail  = "The property, [#propertyName#], in Preside component, [#objectName#], declared a [#property.relationship#] relationship with the object [#property.relatedTo#]; this object could not be found."
						);
					}

					property.relatedViaSourceFk   = property.relatedViaSourceFk   ?: objectName;
					property.relatedViaTargetFk   = property.relatedViaTargetFk   ?: property.relatedTo;
					property.relationshipIsSource = property.relationshipIsSource ?: true;
					property.relatedVia           = property.relatedVia           ?: "";

					if ( !Len( Trim( property.relatedVia ) ) ) {
						property.relatedVia = ( objectName < property.relatedTo ) ? "#objectName#__join__#property.relatedTo#" : "#property.relatedTo#__join__#objectName#";
					}

					if ( property.relatedViaSourceFk == property.relatedViaTargetFk ) {
						property.relatedViaSourceFk = "source_" & property.relatedViaSourceFk;
						property.relatedViaTargetFk = "target_" & property.relatedViaTargetFk;
					}

					if ( !StructKeyExists( objects, property.relatedVia ) ) {
						var pivotObjArgs = {
							  sourceObject       = object.meta
							, targetObject       = objects[ property.relatedTo ].meta
							, pivotObjectName    = property.relatedVia
							, sourcePropertyName = property.relatedViaSourceFk
							, targetPropertyName = property.relatedViaTargetFk
						};

						if ( !property.relationshipIsSource ) {
							var tmp = pivotObjArgs.sourceObject;
							pivotObjArgs.sourceObject = pivotObjArgs.targetObject;
							pivotObjArgs.targetObject = tmp;
						}

						autoObject = _getObjectReader().getAutoPivotObjectDefinition( argumentCollection=pivotObjArgs );

						objects[ property.relatedVia ] = {
							  meta     = autoObject
							, instance = "auto_generated"
						};
						objectNames.append( autoObject.name );
					}

					if ( !StructKeyExists( m2mRelationships, objectName ) ) {
						m2mRelationships[ objectName ] = {};
					}
					if ( !StructKeyExists( m2mRelationships[objectName], property.relatedTo ) ) {
						m2mRelationships[ objectName ][ property.relatedTo ] = [];
					}
					m2mRelationships[ objectName ][ property.relatedTo ].append( {
						  type         = "many-to-many"
						, required     = property.required
						, pivotObject  = property.relatedVia
						, sourceObject = property.relationshipIsSource ? objectName : property.relatedTo
						, sourceFk     = property.relatedViaSourceFk
						, targetFk     = property.relatedViaTargetFk
						, propertyName = propertyName
					} );

				} else if ( property.relationship == "many-to-one" ) {

					if ( not StructKeyExists( objects, property.relatedto ) ) {
						throw(
							  type    = "RelationshipGuidance.BadRelationship"
							, message = "Object, [#property.relatedTo#], could not be found"
							, detail  = "The property, [#propertyName#], in Preside component, [#objectName#], declared a [#property.relationship#] relationship with the object [#property.relatedTo#]; this object could not be found."
						);
					}

					var idField = objects[ property.relatedto ].meta.idField ?: "id";

					if ( !StructKeyExists( property, "onDelete" ) ){
						property.onDelete = ( property.required ? "error" : "set null" );
					}
					if ( !StructKeyExists( property, "onUpdate" ) ){
						property.onUpdate = "cascade";
					}

					keyName = "fk_#LCase( Hash( LCase( SerializeJson( property ) & objectName ) ) )#";

					if ( not StructKeyExists( object.meta, "relationships" ) ) {
						object.meta.relationships = {};
					}

					object.meta.relationships[ keyName ] = {
						  pk_table  = objects[ property.relatedto ].meta.tableName
						, fk_table  = object.meta.tableName
						, pk_column = idField
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
						, pk        = idField
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
						, required = false
						, pk       = idField
						, fk       = propertyName
						, onUpdate = property.onUpdate
						, onDelete = property.onDelete
						, alias    = _calculateOneToManyAlias( property.relatedTo, objects[ property.relatedTo ], objectName, propertyName )
					} );

					property.type      = objects[ property.relatedto ].meta.properties[ idField ].type;
					property.dbType    = objects[ property.relatedto ].meta.properties[ idField ].dbType;
					property.maxLength = objects[ property.relatedto ].meta.properties[ idField ].maxLength;
				} else if ( property.relationship == "one-to-many" ) {
					if ( not StructKeyExists( objects, property.relatedto ) ) {
						throw(
							  type    = "RelationshipGuidance.BadRelationship"
							, message = "Object, [#property.relatedTo#], could not be found"
							, detail  = "The property, [#propertyName#], in Preside component, [#objectName#], declared a [#property.relationship#] relationship with the object [#property.relatedTo#]; this object could not be found."
						);
					}
					var relationshipKey = property.relationshipKey ?: objectName;

					if ( !StructKeyExists( objects[ property.relatedTo ].meta.properties, relationshipKey ) ) {
						throw(
							  type    = "RelationshipGuidance.BadRelationship"
							, message = "Object property, [#property.relatedTo#.#relationshipKey#], could not be found"
							, detail  = "The property, [#propertyName#], in Preside component, [#objectName#], declared a [#property.relationship#] relationship with the object [#property.relatedTo#] using foreign key property named, [#relationshipKey#]. The property could not be found."
						);
					}
				} else if ( property.relationship == "select-data-view" )  {
					var view     = property.relatedto ?: "";
					var viewArgs = _getSelectDataViewService().getViewArgs( property.relatedto );
					var idField  = objects[ objectName ].meta.idField ?: "id";

					if ( Len( Trim( viewArgs.objectName ?: "" ) ) ) {
						relationships[ objectName ][ viewArgs.objectName ] = relationships[ objectName ][ viewArgs.objectName ] ?: [];
						relationships[ objectName ][ viewArgs.objectName ].append({
							  type           = "select-data-view"
							, required       = false
							, pk             = property.relationshipKey ?: "" // todo raise error if bad
							, fk             = idField
							, onUpdate       = "error"
							, onDelete       = "error"
							, alias          = propertyName
							, selectDataView = view
						});
					} else {
						// TODO, raise error
					}
				}
			}
		}

		for( i=1; i lte ArrayLen( objectNames ); i++ ) {
			objectName = objectNames[ i ];
			pkMappings[ objectName ] = objects[ objectName ].meta.idField ?: "id";
		}

		_setRelationships( relationships );
		_setManyToManyRelationships( m2mRelationships );
		_setPkMappings( pkMappings );
	}

	public struct function getObjectRelationships( required string objectName ) {
		var relationships = _getRelationships();

		if ( StructKeyExists( relationships, arguments.objectName ) ) {
			return relationships[ arguments.objectName ];
		}

		return {};
	}

	public string function resolveRelationshipPathToTargetObject( required string sourceObject, required string relationshipPath ) {
		var pathPieces    = ListToArray( arguments.relationshipPath, "$" );
		var currentSource = arguments.sourceObject;

		for( var relationshipPiece in pathPieces ) {
			var relationship = _findColumnRelationship( currentSource, relationshipPiece );

			if ( not StructCount( relationship ) ) {
				return pathPieces.len() == 1 ? pathPieces[1] : "";
				break;
			}

			currentSource = relationship.object;
		}

		return currentSource;
	}

// PRIVATE HELPERS
	private array function _calculateColumnJoins(
		  required string objectName
		, required string target
		, required array  existingJoins
		, required string forceJoins

	) {
		var currentSource   = arguments.objectName;
		var targetPos       = 0;
		var joins           = [];
		var joinAlias       = "";
		var currentAlias    = "";
		var currentJoinType = "inner";
		var pkMappings      = _getPkMappings();

		while( targetPos lt ListLen( target, "$" ) ) {
			var targetCol    = ListGetAt( target, ++targetPos, "$" );
			var relationship = _findColumnRelationship( currentSource, targetCol );
			var joinType     = "";

			if (  Len( Trim ( arguments.forceJoins ) ) ) {
				joinType = arguments.forceJoins;
			} else if ( currentJoinType == "left" ) {
				joinType = "left";
			} else if ( IsBoolean( relationship.required ?: "" ) && relationship.required ) {
				joinType = "inner";
			} else {
				joinType = "left";
			}

			currentJoinType = joinType;

			if ( not StructCount( relationship ) ) {
				return [];
			}

			if ( relationship.type eq "many-to-many" ) {
				ArrayAppend( joins, {
					  type               = joinType
					, joinToObject       = relationship.pivotObject
					, joinFromObject     = currentSource
					, joinFromAlias      = Len( Trim( currentAlias ) ) ? currentAlias : currentSource
					, joinFromProperty   = pkMappings[ currentSource ]
					, joinToProperty     = ( relationship.sourceObject == currentSource ? relationship.sourceFk : relationship.targetFk )
					, manyToManyProperty = relationship.propertyName
				} );
				currentAlias    = relationship.pivotObject;
			}

			joinAlias = ListAppend( joinAlias, targetCol, "$" );

			var join = { type=joinType };

			switch( relationship.type ){
				case "many-to-many":
					join.append({
						  joinFromObject   = relationship.pivotObject
						, joinFromAlias    = Len( Trim( currentAlias ) ) ? currentAlias : relationship.pivotObject
						, joinFromProperty = ( relationship.sourceObject == currentSource ? relationship.targetFk : relationship.sourceFk )
						, joinToObject     = relationship.object
						, joinToProperty   = pkMappings[ relationship.object ]
					});
				break;
				case "many-to-one":
					join.append({
						  joinFromObject   = currentSource
						, joinFromAlias    = Len( Trim( currentAlias ) ) ? currentAlias : currentSource
						, joinFromProperty = relationship.fk
						, joinToObject     = relationship.object
						, joinToProperty   = relationship.pk
					});
				break;
				case "one-to-many":
					join.append({
						  joinFromObject   = currentSource
						, joinFromAlias    = Len( Trim( currentAlias ) ) ? currentAlias : currentSource
						, joinFromProperty = relationship.pk
						, joinToObject     = relationship.object
						, joinToProperty   = relationship.fk
					});
				break;
				case "select-data-view":
					join.append({
						  selectDataView = relationship.selectDataView
						, subQueryAlias  = relationship.alias
						, subQueryColumn = relationship.pk
						, joinToTable    = Len( currentAlias ) ? currentAlias : currentSource
						, joinToColumn   = relationship.fk
					});
				break;
			}

			currentSource = relationship.object;
			currentAlias  = joinAlias;

			if ( joinAlias neq relationship.object && relationship.type != "select-data-view" ) {
				join.tableAlias = joinAlias;
			}

			ArrayAppend( joins, join );
		}

		return joins;
	}

	private struct function _findColumnRelationship( required string objectName, required string columnName ) {
		var found = {};
		var relationships = _getRelationships();
		relationships = relationships[ arguments.objectName ] ?: {};

		for( var foreignObj in relationships ){
			for( var join in relationships[ foreignObj ] ) {
				if ( join.type == "many-to-one" and join.fk == arguments.columnName ) {
					found = Duplicate( join );
					found.object = foreignObj;
					return found;
				} else if ( join.type == "one-to-many" && join.alias == arguments.columnName ) {
					found = Duplicate( join );
					found.object = foreignObj;
					return found;
				} else if ( join.type == "select-data-view" && join.alias == arguments.columnName ) {
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
				if ( join.propertyName == arguments.columnName ) {
					found = Duplicate( join );
					found.object = foreignObj;
					return found;
				}
			}
		}

		return {};
	}

	private boolean function _joinExists( required struct join, required array joins ) {
		var cleanedJoin = Duplicate( join );
		cleanedJoin.delete( "manyToManyProperty" );

		for( var existingJoin in arguments.joins ) {
			var cleanedExistingJoin = Duplicate( existingJoin );
			cleanedExistingJoin.delete( "manyToManyProperty" );

			var isSame = cleanedExistingJoin.count() == cleanedJoin.count();
			if ( isSame ) {
				for( var key in cleanedJoin ) {
					if ( !StructKeyExists( cleanedExistingJoin, key ) || cleanedExistingJoin[ key ] != cleanedJoin[ key ] ) {
						isSame = false;
						break;
					}
				}
			}

			if ( isSame ) {
				return true;
			}
		}

		return false;
	}

	private string function _calculateOneToManyAlias( required string oneObjectName, required struct oneObject, required string manyObjectName, required string fkName ) {
		for ( var propertyName in oneObject.meta.properties ) {
			var property        = oneObject.meta.properties[ propertyName ];
			var relationship    = property.relationship    ?: "";
			var relatedTo       = property.relatedTo       ?: "";
			var relationshipKey = property.relationshipKey ?: arguments.oneObjectName;

			if ( relationship == "one-to-many" && relatedTo == manyObjectName && relationshipKey == fkName ) {
				return propertyName;
			}
		}

		return "";
	}

// GETTERS AND SETTERS
	private any function _getObjectReader() {
		return _objectReader;
	}
	private void function _setObjectReader( required any objectReader ) {
		_objectReader = arguments.objectReader;
	}

	private any function _getRelationships() {
		return _relationships;
	}
	private void function _setRelationships( required any relationships ) {
		_relationships = arguments.relationships;
	}

	private any function _getManyToManyRelationships() {
		return _manyToManyRelationships;
	}
	private void function _setManyToManyRelationships( required any manyToManyRelationships ) {
		_manyToManyRelationships = arguments.manyToManyRelationships;
	}

	private struct function _getPkMappings() {
		return _pkMappings;
	}
	private void function _setPkMappings( required struct pkMappings ) {
		_pkMappings = arguments.pkMappings;
	}

	private any function _getSelectDataViewService() {
	    return _selectDataViewService;
	}
	private void function _setSelectDataViewService( required any selectDataViewService ) {
	    _selectDataViewService = arguments.selectDataViewService;
	}
}