/**
 * Handler that provides default actions for building links to admin object
 * screens.
 *
 */
component {

	property name="dataManagerService" inject="dataManagerService";
	property name="customizationService" inject="dataManagerCustomizationService";

	private string function buildListingLink( event, rc, prc, args={} ) {
		var objectName = args.objectName  ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.object"
			, queryString = _queryString( "id=#objectName#", args )
		);
	}

	private string function buildViewRecordLink( event, rc, prc, args={} ) {
		var objectName  = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "read" ) ) {
			var recordId    = args.recordId ?: "";
			var language    = args.language ?: "";
			var version     = args.version  ?: "";
			var queryString = "object=#objectName#&id=#recordId#";

			if ( language.len() ) {
				queryString &= "&language=#language#";
			}
			if ( Val( version ) || version.len() ) {
				queryString &= "&version=#version#";
			}

			return event.buildAdminLink(
				  linkto      = "datamanager.viewRecord"
				, queryString = _queryString( queryString, args )
			);
		}
		return "";
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "add" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.addRecord"
				, queryString = _queryString( "object=#objectName#", args )
			);
		}

		return "";
	}

	private string function buildAddRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "add" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.addRecordAction"
				, queryString = _queryString( "object=#objectName#", args )
			);
		}

		return "";
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "edit" ) ) {
			var recordId     = args.recordId   ?: "";
			var resultAction = args.resultAction ?: "";
			var version      = args.version ?: "";
			var queryString = "object=#objectName#&id=#recordId#";

			if ( resultAction.len() ) {
				queryString &= "&resultAction=#resultAction#";
			}
			if ( Val( version ) || version.len() ) {
				queryString &= "&version=#version#";
			}

			return event.buildAdminLink(
				  linkto      = "datamanager.editRecord"
				, queryString = _queryString( queryString, args )
			);
		}

		return "";
	}

	private string function buildEditRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "edit" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.editRecordAction"
				, queryString = _queryString( "object=#objectName#", args )
			);
		}

		return "";
	}

	private string function buildCloneRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "clone" ) ) {
			var recordId     = args.recordId ?: "";
			var queryString = "object=#objectName#&id=#recordId#";

			return event.buildAdminLink(
				  linkto      = "datamanager.cloneRecord"
				, queryString = _queryString( queryString, args )
			);
		}

		return "";
	}

	private string function buildCloneRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "clone" ) ) {
			var queryString = "object=#objectName#";

			return event.buildAdminLink(
				  linkto      = "datamanager.cloneRecordAction"
				, queryString = _queryString( queryString, args )
			);
		}

		return "";
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = args.recordId   ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "delete" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.deleteRecordAction"
				, queryString = _queryString( "object=#objectName#&id=#recordId#", args )
			);
		}

		return "";
	}

	private string function buildTranslateRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "translate" ) ) {
			var recordId     = args.recordId ?: "";
			var language     = args.language ?: "";
			var version      = args.version  ?: "";
			var fromDataGrid = IsTrue( args.fromDataGrid ?: "" );
			var queryString  = "object=#objectName#&id=#recordId#&language=#language#&fromDataGrid=#fromDataGrid#";

			if ( Val( version ) || version.len() ) {
				queryString &= "&version=" & version;
			}

			return event.buildAdminLink(
				  linkto      = "datamanager.translateRecord"
				, queryString = _queryString( queryString, args )
			);
		}
		return "";
	}

	private string function buildSortRecordsLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isSortable( objectName ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.sortRecords"
				, queryString = _queryString( "object=#objectName#", args )
			);
		}

		return "";
	}

	private string function buildManagePermsLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.managePerms"
			, queryString = _queryString( "object=#objectName#", args )
		);
	}

	private string function buildAjaxListingLink( event, rc, prc, args={} ) {
		var objectName     = args.objectName ?: "";
		var qs             = "id=#objectName#";
		var extraQs        = "";
		var additionalArgs = [ "useMultiActions", "gridFields", "isMultilingual", "draftsEnabled" ];

		if ( customizationService.objectHasCustomization( objectName, "getAdditionalQueryStringForBuildAjaxListingLink" ) ) {
			extraQs = customizationService.runCustomization(
				  objectName = objectName
				, action     = "getAdditionalQueryStringForBuildAjaxListingLink"
				, args       = args
			);

			extraQs = extraQs ?: "";
			extraQs = IsSimpleValue( extraQs ) ? extraQs : "";

		}


		for( var arg in additionalArgs ) {
			if ( StructKeyExists( args, arg ) ) {
				qs &= "&#arg#=#args[ arg ]#";
			}
		}

		if ( Len( Trim( extraQs ) ) ) {
			qs &= "&#extraQs#";
		}

		return event.buildAdminLink(
			  linkto      = "datamanager.getObjectRecordsForAjaxDataTables"
			, queryString = _queryString( qs, args )
		);
	}

	private string function buildMultiRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.multiRecordAction"
			, queryString = _queryString( "object=#objectName#", args )
		);
	}

	private string function buildBatchEditFieldLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.batchEditField"
			, queryString = _queryString( "object=#objectName#", args )
		);
	}

	private string function buildBatchEditActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.batchEditAction"
			, queryString = _queryString( "object=#objectName#", args )
		);
	}

	private string function buildExportDataActionLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo = "datamanager.exportDataAction", queryString=args.queryString ?: "" );
	}

	private string function buildDataExportConfigModalLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkTo      = "datamanager.dataExportConfigModal"
			, queryString = _queryString( "object=#objectName#", args )
		);
	}

	private string function buildRecordHistoryLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";
		var recordId   = args.recordId ?: "";

		return event.buildAdminLink(
			  linkTo      = "datamanager.recordHistory"
			, queryString = _queryString( "object=#objectName#&id=#recordId#", args )
		);
	}

	private string function buildGetNodesForTreeViewLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkTo      = "datamanager.getNodesForTreeView"
			, queryString = _queryString( "object=#objectName#", args )
		);
	}

// helpers
	private string function _queryString( required string querystring, struct args={} ) {
		var extraQs = args.queryString ?: "";

		if ( extraQs.len() ) {
			return arguments.queryString & "&" & extraQs;
		}

		return arguments.queryString;
	}
}