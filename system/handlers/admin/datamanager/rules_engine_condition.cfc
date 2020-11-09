component {
	property name="rulesEngineFilterService" inject="RulesEngineFilterService";

	private void function preAddRecordAction( event, rc, prc, args={} ){
		if ( !args.validationResult.validated() ) {
			args.formData.delete( "context" );
		}
	}

	private string function getAdditionalQueryStringForBuildAjaxListingLink( event, rc, prc, args={} ) {
		if ( event.isDataManagerRequest() && event.getCurrentAction() == "manageFilters" ) {
			return "filterobject=" & ( prc.objectName ?: "" );
		}

		return "";
	}

	private void function preFetchRecordsForGridListing( event, rc, prc, args={} ) {
		args.extraFilters = args.extraFilters ?: [];

		rulesEngineFilterService.getRulesEngineSelectArgsForEdit( args=args );

		var filterObject = rc.filterObject ?: "";
		if ( Len( filterObject ) ) {
			ArrayAppend( args.extraFilters, { filter = {
				filter_object = filterObject
			} } );
		}
	}

	private void function preEditRecordAction( event, rc, prc, args={} ) {
		switch ( args.formData.filter_sharing_scope ?: "" ) {
			case "global":
				args.formData.owner            = "";
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
			case "individual":
				args.formData.user_groups      = "";
				args.formData.allow_group_edit = 0;
				break;
		}
	}

	private array function getRecordActionsForGridListing( event, rc, prc, args={} ) {
		var record    = args.record ?: {};
		var recordId  = record.id   ?: "";
		var kind      = record.kind ?: "";
		var actions   = [];
		var canEdit   = true;
		var canDelete = true;

		if ( kind == "filter" ) {
			canEdit = canDelete = runEvent(
				  event = "admin.datamanager._checkPermission"
				, private = true
				, prepostExempt = true
				, eventArguments = {
					  key          = "manageFilters"
					, object       = record.filter_object ?: ""
					, throwOnError = false
				  }
			);

			canDelete = canDelete && !rulesEngineFilterService.filterIsUsed( recordId );
		} else {
			canEdit   = hasCmsPermission( "rulesengine.edit" );
			canDelete = hasCmsPermission( "rulesengine.delete" );
		}

		if ( canEdit ) {
			ArrayAppend( actions, {
				  link       = event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="editRecord" )
				, icon       = "fa-pencil"
				, contextKey = "e"
			} );
		}

		if ( canDelete ) {
			ArrayAppend( actions, {
				  link       = event.buildAdminLink( objectName="rules_engine_condition", recordId=recordId, operation="deleteRecordAction" )
				, icon       = "fa-trash-o"
				, contextKey = "d"
				, class      = "confirmation-prompt"
				, title      = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ translateResource( "preside-objects.rules_engine_condition:title.singular" ), record.condition_name ] )
			} );
		} else {
			ArrayAppend( actions, {
				  link = "##"
				, icon = "fa-trash-o light-grey disabled"
			} );
		}

		return actions;
	}

	private string function buildEditRecordLink( event, rc, prc, args={} ) {
		var qs = "id=#( args.recordId ?: '' )#";

		if ( Len( args.queryString ?: "" ) ) {
			qs &= "&#args.queryString#";
		}

		return event.buildAdminLink( linkto="rulesengine.editCondition", queryString=qs );
	}

	private string function buildDeleteRecordActionLink( event, rc, prc, args={} ) {
		var qs = "id=#( args.recordId ?: '' )#";

		if ( Len( args.queryString ?: "" ) ) {
			qs &= "&#args.queryString#";
		}

		return event.buildAdminLink( linkto="rulesengine.deleteConditionAction", queryString=qs );
	}
}