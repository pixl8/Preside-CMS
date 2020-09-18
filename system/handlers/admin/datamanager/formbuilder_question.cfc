component extends="preside.system.base.AdminHandler" {

	property name="datamanagerService" inject="datamanagerService";

// CUSTOM PUBLIC PAGES
	public void function addRecordStep1( event, rc, prc ) {
		event.initializeDatamanagerPage( objectName="formbuilder_question" );

		var objectTitleSingular = prc.objectTitle ?: "";
		var addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[  objectTitleSingular  ] );

		prc.pageIcon  = "plus";
		prc.pageTitle = addRecordTitle;

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:datamanager.addrecord.breadcrumb.title", data=[ objectTitleSingular ] )
			, link  = ""
		);

		prc.cancelLink    = event.buildAdminLink( objectName="formbuilder_question" );
		prc.addRecordLink = event.buildAdminLink( linkto="datamanager.addrecord", queryString="object=formbuilder_question" );
		prc.formName      = "preside-objects.formbuilder_question.admin.add.step1";
	}

// DATA MANAGER CUSTOMIZATIONS
	private boolean function checkPermission( event, rc, prc, args={} ) {
		var objectName       = "formbuilder_question";
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

	private string function buildAddRecordLink( event, rc, prc, args={} ) {
		return event.buildAdminLink(
			  linkTo      = "datamanager.formbuilder_question.addRecordStep1"
			, queryString = args.queryString ?: ""
		);
	}
}

