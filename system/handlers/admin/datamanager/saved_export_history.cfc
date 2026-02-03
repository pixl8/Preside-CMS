/**
 * @feature admin and dataExport
 */
component {
	property name="scheduledExportService" inject="ScheduledExportService";
	property name="datamanagerService"        inject="datamanagerService";

	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName       = "saved_export_history";
		var allowedOps       = datamanagerService.getAllowedOperationsForObject( objectName );
		var permissionsBase  = "savedExport"
		var alwaysDisallowed = [ "manageContextPerms" ];
		var operationMapped  = [ "read", "add", "edit", "delete", "batchdelete", "clone" ];
		var permissionKey    = "#permissionsBase#.#( args.key ?: "" )#";
		var hasPermission    = !alwaysDisallowed.find( args.key )
		                    && ( !operationMapped.find( args.key ) || allowedOps.find( args.key ) )
		                    && hasCmsPermission( permissionKey );

		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

	private array function getActionsForGridListing( event, rc, prc, args={} ) {
		var records   = args.records ?: QueryNew('');
		var actions   = [];
		var canDelete = IsTrue( prc.canDelete ?: "" );

		for ( var record in records ) {
			var recordActions = [];
			var filepath      = scheduledExportService.getHistoryExportFile( record.id );

			if ( !isEmpty( filepath ) ) {
				recordActions.append( {
					  link       = event.buildLink( fileStorageProvider="ScheduledExportStorageProvider", fileStoragePath="/#filepath#" )
					, icon       = "fa-download"
					, contextKey = "d"
				} );
			}

			if ( canDelete ) {
				var deleteRecordLink  = event.buildAdminLink( objectName="saved_export_history", recordId="{id}", operation="deleteRecordAction" );
				var deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ lCase( prc.objectTitle ?: "" ), "{recordlabel}" ] );

				recordActions.append( {
					  link       = deleteRecordLink.replace( "{id}", record.id )
					, icon       = "fa-trash-o"
					, contextKey = "d"
					, class      = "confirmation-prompt"
					, title      = deleteRecordTitle.replace( "{recordlabel}", filepath, "all" )
				} );
			}

			ArrayAppend( actions, renderView( view="/admin/datamanager/_listingActions", args={ actions=recordActions } ) );
		}

		return actions;
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName = rc.object ?: "";
		var recordId   = rc.id     ?: "";

		if ( objectName eq "saved_export" ) {
			return "saved_export=#recordId#";
		} else {
			return "";
		}
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		var savedExport= rc.saved_export ?: "";

		if ( !isEmpty( savedExport ) ) {
			args.extraFilters = args.extraFilters ?: [];

			args.extraFilters.append( { filter={ saved_export=savedExport } } );
		}
	}

	private void function preDeleteRecordAction( event, rc, prc, args={} ) {
		if ( !isEmptyString( args.cancelUrl ?: "" ) and !isEmptyString( args.postActionUrl ?: "" ) ) {
			args.postActionUrl = args.cancelUrl;
		}
	}
}