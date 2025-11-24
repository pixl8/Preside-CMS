component extends="coldbox.system.Interceptor" {

	property name="draftManagerService" inject="delayedInjector:DraftManagerService";

	public void function configure() {}

	public void function postReadPresideObject( event, interceptData ) {
		var meta       = interceptData.objectMeta ?: {};
		var objectName = ListLast( meta.name, "." );

		if ( isTrue( meta.draftManagerEnabled ?: false ) ) {
			var properties    = meta.properties    ?: {};
			var propertyNames = meta.propertyNames ?: [];

			if ( !StructKeyExists( properties, "draftmanager_status" ) ) {
				properties.draftmanager_status = {
					  formula        = "concat( '#objectName#.', ${prefix}id )"
					, renderer       = "DraftStatus"
					, adminViewGroup = "draftManager"
					, autoFilter     = false
				};

				ArrayAppend( propertyNames, "draftmanager_status" );

				meta.datamanagerGridFields = ListAppend( meta.datamanagerGridFields, "draftmanager_status" );
			}

			if ( !StructKeyExists( properties, "draftmanager_datecreated" ) ) {
				properties.draftmanager_datecreated = {
					  formula        = "concat( '#objectName#.', ${prefix}id )"
					, renderer       = "DraftDate"
					, adminViewGroup = "draftManager"
					, autoFilter     = false
				};

				ArrayAppend( propertyNames, "draftmanager_datecreated" );
			}

			if ( !StructKeyExists( properties, "draftmanager_security_user_created" ) ) {
				properties.draftmanager_security_user_created = {
					  formula        = "concat( '#objectName#.', ${prefix}id )"
					, renderer       = "DraftSecurityUser"
					, adminViewGroup = "draftManager"
					, autoFilter     = false
				};

				ArrayAppend( propertyNames, "draftmanager_security_user_created" );
			}

			if ( !StructKeyExists( properties, "draftmanager_datemodified" ) ) {
				properties.draftmanager_datemodified = {
					  formula        = "concat( '#objectName#.', ${prefix}id )"
					, renderer       = "DraftDate"
					, adminViewGroup = "draftManager"
					, autoFilter     = false
				};

				ArrayAppend( propertyNames, "draftmanager_datemodified" );
			}

			if ( !StructKeyExists( properties, "draftmanager_security_user_modified" ) ) {
				properties.draftmanager_security_user_modified = {
					  formula        = "concat( '#objectName#.', ${prefix}id )"
					, renderer       = "DraftSecurityUser"
					, adminViewGroup = "draftManager"
					, autoFilter     = false
				};

				ArrayAppend( propertyNames, "draftmanager_security_user_modified" );
			}
		}
	}

	public void function postViewRecord( event, interceptData ) {
		if ( !isFeatureEnabled( "draftManager" ) ) {
			return;
		}

		var objectName = interceptData.objectName ?: "";

		if ( draftManagerService.isManagerEnabled( objectName=objectName ) ) {
			var recordId = interceptData.recordId ?: "";

			for ( var k in [ "renderedRecord", "preViewRecordContent" ] ) {
				if ( StructKeyExists( prc, k ) ) {
					prc[ k ] = _getDraftAlert( objectName=objectName, recordId=recordId ) & prc[ k ];
				}
			}
		}
	}

	public void function preEditRecord( event, interceptData ) {
		if ( !isFeatureEnabled( "draftManager" ) ) {
			return;
		}

		var objectName = interceptData.objectName ?: "";
		var recordId   = interceptData.recordId   ?: "";

		if ( draftManagerService.isManagerEnabled( objectName=objectName ) ) {
			var draft = draftManagerService.getDraftForObject( objectName=objectName, recordId=recordId );

			if ( !isEmptyString( draft.id ?: "" ) ) {
				setNextEvent( url=event.buildAdminLink( objectName="draftmanager_draft", operation="editRecord", recordId=draft.id ) );
			}
		}
	}

	public void function postEditRecord( event, interceptData ) {
		if ( !isFeatureEnabled( "draftManager" ) ) {
			return;
		}

		var objectName = interceptData.objectName ?: "";

		if ( objectName == "draftmanager_draft" ) {
			var breadcrumbs = event.getAdminBreadCrumbs();
			var length = ArrayLen( breadcrumbs )
			if ( length ) {
				ArrayDeleteAt( breadcrumbs, length );

				event.addAdminBreadCrumb(
					  title = translateResource( uri="draftManager:breadcrumb.edit.title" )
					, link  = ""
				);
			}
		}
	}

	private string function _getDraftAlert(
		  required string objectName
		, required string recordId
	) {
		var draft = draftManagerService.getDraftForObject( objectName=arguments.objectName, recordId=arguments.recordId );

		return renderView( view="admin/draftManager/_alertRecord", args={
			  objectName = arguments.objectName
			, recordId   = arguments.recordId
			, draftId    = draft.id ?: ""
		} );
	}

}