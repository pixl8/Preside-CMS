component extends="preside.system.base.AdminHandler" {

	property name="datamanagerService"   inject="datamanagerService";
	property name="customizationService" inject="dataManagerCustomizationService";

// VIEWING RECORD
	private void function objectBreadcrumb( event, rc, prc, args={} ) {
		var questionId = prc.record.question ?: "";
		var objTitle   = translateResource( "preside-objects.formbuilder_question_response:title" );

		if ( Len( Trim( questionId ) ) ) {
			customizationService.runCustomization(
				  objectName     = "formbuilder_question"
				, action         = "objectBreadcrumb"
				, defaultHandler = "admin.datamanager._objectBreadcrumb"
				, args           = {
					  objectName  = "formbuilder_question"
					, objectTitle = translateResource( "preside-objects.formbuilder_question:title" )
				  }
			);
			customizationService.runCustomization(
				  objectName     = "formbuilder_question"
				, action         = "recordBreadcrumb"
				, defaultHandler = "admin.datamanager._recordBreadcrumb"
				, args           = { objectName="formbuilder_question", recordId=questionId, recordLabel=renderLabel( "formbuilder_question", questionId ) }
			);
			event.addAdminBreadCrumb(
				  title = objTitle
				, link  = event.buildAdminLink( objectName="formbuilder_question", recordId=questionId )
			);
		} else {
			event.addAdminBreadCrumb(
				  title = objTitle
				, link  = event.buildAdminLink( objectName="formbuilder_question_response" )
			);
		}
	}



// PERMISSIONS CHECKING
	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName       = "formbuilder_question_response";
		var allowedOps       = datamanagerService.getAllowedOperationsForObject( objectName );
		var permissionsBase  = "formquestions"
		var alwaysDisallowed = [ "manageContextPerms" ];
		var operationMapped  = [ "read", "add", "edit", "delete", "clone", "batchdelete", "batchedit" ];
		var permissionKey    = "#permissionsBase#.#( args.key ?: "" )#";
		var hasPermission    = !alwaysDisallowed.find( args.key )
		                    && ( !operationMapped.find( args.key ) || allowedOps.find( args.key ) )
		                    && hasCmsPermission( permissionKey );


		if ( !hasPermission && IsTrue( args.throwOnError ?: "" ) ) {
			event.adminAccessDenied();
		}

		return hasPermission;
	}

}

