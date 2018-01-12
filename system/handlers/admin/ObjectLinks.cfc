/**
 * Handler that provides default actions for building links to admin object
 * screens.
 *
 */
component {

	property name="dataManagerService" inject="dataManagerService";
	property name="customizationService" inject="dataManagerCustomizationService";

	private string function buildListingLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.object"
			, queryString = "id=#objectName#"
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
				, queryString = queryString
			);
		}
		return "";
	}

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "add" ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.addRecord"
				, queryString = "object=#objectName#"
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
				, queryString = queryString
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
				, queryString = "object=#objectName#&id=#recordId#"
			);
		}

		return "";
	}

	private string function buildTranslateRecordLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isOperationAllowed( objectName, "edit" ) ) {
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
				, queryString = queryString
			);
		}
		return "";
	}

	private string function buildSortRecordsLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		if ( dataManagerService.isSortable( objectName ) ) {
			return event.buildAdminLink(
				  linkto      = "datamanager.sortRecords"
				, queryString = "object=#objectName#"
			);
		}

		return "";
	}

	private string function buildManagePermsLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.managePerms"
			, queryString = "object=#objectName#"
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
			if ( args.keyExists( arg ) ) {
				qs &= "&#arg#=#args[ arg ]#";
			}
		}

		if ( Len( Trim( extraQs ) ) ) {
			qs &= "&#extraQs#";
		}

		return event.buildAdminLink(
			  linkto      = "datamanager.getObjectRecordsForAjaxDataTables"
			, queryString = qs
		);
	}

	private string function buildMultiRecordActionLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkto      = "datamanager.multiRecordAction"
			, queryString = "object=#objectName#"
		);
	}

	private string function buildExportDataActionLink( event, rc, prc, args={} ) {
		return event.buildAdminLink( linkTo = "datamanager.exportDataAction" );
	}

	private string function buildDataExportConfigModalLink( event, rc, prc, args={} ) {
		var objectName = args.objectName ?: "";

		return event.buildAdminLink(
			  linkTo      = "datamanager.dataExportConfigModal"
			, queryString = "object=#objectName#"
		);
	}

}