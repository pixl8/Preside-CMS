/**
 * @feature customFields
 */
component extends="coldbox.system.Interceptor" {

	property name="customFieldsService"             inject="delayedInjector:customFieldsService";
	property name="customFieldsPropertyInjector"    inject="delayedInjector:customFieldsPropertyInjector";
	property name="customFieldsValueTableService"   inject="delayedInjector:customFieldsValueTableService";
	property name="presideObjectService"            inject="delayedInjector:presideObjectService";
	property name="versioningService"               inject="delayedInjector:versioningService";
	property name="permissionService"               inject="delayedInjector:permissionService";
	property name="formsService"                    inject="delayedInjector:formsService";

	public void function configure() {}

	public void function postReadPresideObjects( event, interceptData ) {
		customFieldsValueTableService.addValueObjects( interceptData.objects ?: {} );
	}

	public void function postLoadPresideObjects( event, interceptData ) {
		customFieldsValueTableService.decorateHostVersionObjects( interceptData.objects ?: {} );
	}

	public void function onApplicationStart() {
		_applyCustomFieldProperties();
		_migrateSharedValues();
	}

	public void function postPresideReload() {
		_applyCustomFieldProperties();
		_migrateSharedValues();
	}

	public void function postDbSyncObjects() {
		_applyCustomFieldProperties();
		_migrateSharedValues();
	}

	public void function preInsertObjectData( event, interceptData ) {
		_stashValues( interceptData );
	}

	public void function postInsertObjectData( event, interceptData ) {
		_persistStashedValues( event, interceptData, interceptData.newId ?: "" );
		_refreshIfDefinitionChanged( interceptData );
	}

	public void function preUpdateObjectData( event, interceptData ) {
		_stashValues( interceptData );
	}

	public void function postUpdateObjectData( event, interceptData ) {
		var recordId = interceptData.id ?: "";
		if ( !Len( Trim( recordId ) ) && IsStruct( interceptData.filter ?: {} ) ) {
			recordId = interceptData.filter.id ?: "";
		}
		if ( IsArray( recordId ) ) {
			recordId = ArrayLen( recordId ) ? recordId[ 1 ] : "";
		}
		_persistStashedValues( event, interceptData, recordId );
		_refreshIfDefinitionChanged( interceptData );
	}

	public void function preDeleteObjectData( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";
		if ( objectName == "custom_field" ) {
			interceptData.customFieldTargetObjects = _targetObjectsForDelete( interceptData );
			return;
		}

		if ( customFieldsService.isObjectEnabled( objectName ) ) {
			var recordId = interceptData.id ?: ( IsStruct( interceptData.filter ?: {} ) ? ( interceptData.filter.id ?: "" ) : "" );
			if ( IsArray( recordId ) ) {
				for( var id in recordId ) {
					customFieldsService.deleteValuesForRecord( objectName, id );
				}
			} else if ( Len( Trim( recordId ) ) ) {
				customFieldsService.deleteValuesForRecord( objectName, recordId );
			}
		}
	}

	public void function postDeleteObjectData( event, interceptData ) {
		var targets = interceptData.customFieldTargetObjects ?: [];
		for( var objectName in targets ) {
			customFieldsPropertyInjector.refreshObject( objectName );
		}
	}

	public void function postExtraTopRightButtonsForObject( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";
		if ( !customFieldsService.isObjectEnabled( objectName ) || !permissionService.hasPermission( permissionKey="customfields.manage" ) ) {
			return;
		}

		var actions = interceptData.actions ?: [];
		ArrayAppend( actions, {
			  link      = event.buildAdminLink( objectName="custom_field", operation="addRecord", queryString="target_object=#objectName#" )
			, btnClass  = "btn-info"
			, iconClass = "fa-puzzle-piece"
			, title     = translateResource( uri="customFields:manage.fields.btn" )
		} );
		ArrayAppend( actions, {
			  link      = event.buildAdminLink( objectName="custom_field", queryString="target_object=#objectName#" )
			, btnClass  = "btn-default"
			, iconClass = "fa-list"
			, title     = translateResource( uri="customFields:list.fields.btn" )
		} );
	}

	public void function postExtraTopRightButtonsForViewRecord( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";
		var recordId   = interceptData.recordId   ?: ( prc.recordId ?: "" );

		if ( !customFieldsService.isObjectEnabled( objectName ) || !Len( Trim( recordId ) ) ) {
			return;
		}

		var record   = presideObjectService.selectData( objectName=objectName, id=recordId );
		var fields   = customFieldsService.listFieldsForRecord( objectName=objectName, record=record, kind="static" );
		var editable = [];
		for( var field in fields ) {
			if ( !customFieldsService.fieldHasInlineForm( objectName, field.slot ?: "custom" ) ) {
				ArrayAppend( editable, field );
			}
		}
		if ( !ArrayLen( editable ) ) {
			return;
		}

		var actions = interceptData.actions ?: [];
		ArrayAppend( actions, {
			  link      = event.buildAdminLink( linkto="customFields.editRecordValues", queryString="object=#objectName#&id=#recordId#" )
			, btnClass  = "btn-info"
			, iconClass = "fa-puzzle-piece"
			, title     = translateResource( uri="customFields:edit.values.btn" )
		} );
	}

	public void function preRenderRecordForViewRecord( event, interceptData ) {
		var objectName = interceptData.objectName ?: "";
		if ( !customFieldsService.isObjectEnabled( objectName ) ) {
			return;
		}

		var recordId = interceptData.recordId ?: "";
		var record   = Len( recordId ) ? presideObjectService.selectData( objectName=objectName, id=recordId ) : {};
		var allowed  = {};
		for( var field in customFieldsService.listFieldsForRecord( objectName=objectName, record=record ) ) {
			allowed[ field.key ] = true;
		}

		interceptData.viewGroups = Duplicate( interceptData.viewGroups ?: { left=[], right=[] } );
		var viewGroups = interceptData.viewGroups;
		for( var col in [ "left", "right" ] ) {
			var groups = viewGroups[ col ] ?: [];
			for( var i=ArrayLen( groups ); i>=1; i-- ) {
				var props = groups[ i ].properties ?: [];
				var kept  = [];
				for( var propertyName in props ) {
					var isCustom = IsTrue( presideObjectService.getObjectPropertyAttribute(
						  objectName    = objectName
						, propertyName  = propertyName
						, attributeName = "customField"
					) );
					if ( !isCustom || StructKeyExists( allowed, propertyName ) ) {
						ArrayAppend( kept, propertyName );
					}
				}
				groups[ i ].properties = kept;
				if ( !ArrayLen( kept ) && ( groups[ i ].id ?: "" ) == "customFields" ) {
					ArrayDeleteAt( groups, i );
				}
			}
		}
	}

	public void function preRenderForm( event, interceptData ) {
		var formName   = interceptData.formName ?: "";
		var objectName = _objectNameFromForm( formName );
		if ( !Len( objectName ) || !customFieldsService.isObjectEnabled( objectName ) ) {
			return;
		}

		var record = interceptData.savedData ?: {};
		if ( !IsStruct( record ) ) {
			record = {};
		}

		var idField  = presideObjectService.getIdField( objectName );
		var recordId = record[ idField ] ?: "";
		if ( Len( Trim( recordId ) ) ) {
			var values = {};
			if ( _isRestoringHistoricalVersion( event, objectName, recordId ) ) {
				values = customFieldsValueTableService.getValuesFromVersion(
					  objectName    = objectName
					, recordId      = recordId
					, versionNumber = Val( event.getValue( "version", 0 ) )
				);
			}
			if ( StructIsEmpty( values ) ) {
				values = customFieldsService.getValues( objectName, recordId );
			}

			StructAppend( record, values, false );
			interceptData.savedData = record;
		}

		var mergeName  = customFieldsService.mergeInlineFieldsIntoForm(
			  formName   = formName
			, objectName = objectName
			, record     = record
		);

		if ( Len( Trim( mergeName ) ) ) {
			var extra = [];
			var existingMerge = interceptData.mergeWithFormName ?: "";

			if ( IsArray( existingMerge ) ) {
				extra = Duplicate( existingMerge );
			} else if ( Len( Trim( existingMerge ) ) ) {
				ArrayAppend( extra, existingMerge );
			}
			ArrayAppend( extra, mergeName );

			if ( ArrayLen( extra ) == 1 ) {
				interceptData.mergeWithFormName = extra[ 1 ];
			} else {
				interceptData.mergeWithFormName = formsService.getMergedFormName( extra[ 1 ], ArraySlice( extra, 2 ) );
			}
		}
	}

	private void function _stashValues( required struct interceptData ) {
		var objectName = arguments.interceptData.objectName ?: "";
		if ( objectName == "custom_field" || !customFieldsService.isObjectEnabled( objectName ) ) {
			return;
		}

		arguments.interceptData.customFieldValues = customFieldsService.extractCustomFieldValues(
			  objectName = objectName
			, data       = arguments.interceptData.data ?: {}
		);

		if ( StructKeyExists( arguments.interceptData, "data" ) && IsStruct( arguments.interceptData.data ) ) {
			for( var fieldKey in arguments.interceptData.customFieldValues ) {
				StructDelete( arguments.interceptData.data, fieldKey );
			}
		}
	}

	private void function _persistStashedValues( required any event, required struct interceptData, required string recordId ) {
		var objectName = arguments.interceptData.objectName ?: "";
		if ( !Len( Trim( arguments.recordId ) ) || !customFieldsService.isObjectEnabled( objectName ) ) {
			return;
		}

		var values = arguments.interceptData.customFieldValues ?: {};
		if ( !IsStruct( values ) ) {
			values = {};
		}

		if ( _isRestoringHistoricalVersion( arguments.event, objectName, arguments.recordId ) ) {
			var restored = customFieldsValueTableService.getValuesFromVersion(
				  objectName    = objectName
				, recordId      = arguments.recordId
				, versionNumber = Val( arguments.event.getValue( "version", 0 ) )
			);
			StructAppend( restored, values, true );
			customFieldsService.saveValues(
				  objectName = objectName
				, recordId   = arguments.recordId
				, values     = restored
				, replaceAll = true
			);
		} else if ( StructCount( values ) ) {
			customFieldsService.saveValues(
				  objectName = objectName
				, recordId   = arguments.recordId
				, values     = values
			);
		}

		try {
			customFieldsService.snapshotRecordValues( objectName, arguments.recordId );
		} catch ( any e ) {
			_logCustomFieldsError( "Custom fields version snapshot failed: #e.message#", e );
		}
	}

	private void function _refreshIfDefinitionChanged( required struct interceptData ) {
		if ( ( arguments.interceptData.objectName ?: "" ) != "custom_field" ) {
			return;
		}

		var target = arguments.interceptData.data.target_object ?: "";
		if ( !Len( Trim( target ) ) && Len( Trim( arguments.interceptData.id ?: "" ) ) ) {
			var field = customFieldsService.getField( arguments.interceptData.id );
			target = field.target_object ?: "";
		}
		if ( Len( Trim( target ) ) ) {
			customFieldsPropertyInjector.refreshObject( target );
		}
	}

	private boolean function _isRestoringHistoricalVersion( required any event, required string objectName, required string recordId ) {
		var versionNumber = Val( arguments.event.getValue( "version", 0 ) );
		if ( !versionNumber || !Len( Trim( arguments.recordId ) ) || !presideObjectService.objectIsVersioned( arguments.objectName ) ) {
			return false;
		}

		var latest = Val( versioningService.getLatestVersionNumber(
			  objectName = arguments.objectName
			, recordId   = arguments.recordId
		) );

		return latest && versionNumber != latest;
	}

	private array function _targetObjectsForDelete( required struct interceptData ) {
		var ids = arguments.interceptData.id ?: "";
		if ( !Len( ids ) && IsStruct( arguments.interceptData.filter ?: {} ) ) {
			ids = arguments.interceptData.filter.id ?: "";
		}
		if ( !Len( ids ) ) {
			return [];
		}
		if ( !IsArray( ids ) ) {
			ids = ListToArray( ids );
		}

		var records = presideObjectService.selectData(
			  objectName   = "custom_field"
			, filter       = { id=ids }
			, selectFields = [ "distinct target_object as target_object" ]
		);
		var objects = [];
		for( var record in records ) {
			ArrayAppend( objects, record.target_object );
		}

		return objects;
	}

	private string function _objectNameFromForm( required string formName ) {
		var match = ReMatchNoCase( "^preside-objects\.([a-z0-9_]+)\.admin\.(add|edit)$", arguments.formName );
		if ( ArrayLen( match ) ) {
			return ListGetAt( arguments.formName, 2, "." );
		}

		return "";
	}

	private void function _applyCustomFieldProperties() {
		try {
			customFieldsPropertyInjector.applyAll();
		} catch ( any e ) {
			_logCustomFieldsError( "Custom fields property injection failed: #e.message#", e );
		}
	}

	private void function _migrateSharedValues() {
		try {
			customFieldsValueTableService.migrateFromSharedTable();
		} catch ( any e ) {
			_logCustomFieldsError( "Custom fields value table migration failed: #e.message#", e );
		}
	}

	private void function _logCustomFieldsError( required string message, required any error ) {
		var logger = getController().getLogBox().getLogger( "default" );
		if ( logger.canError() ) {
			logger.error( arguments.message, arguments.error );
		}
	}

}
