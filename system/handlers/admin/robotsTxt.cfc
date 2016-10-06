component extends="preside.system.base.AdminHandler" {
	property name="messageBox"                inject="coldbox:plugin:messageBox";
	property name="rootFolderStorageProvider" inject="rootFolderStorageProvider";

	// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !hasCmsPermission( permissionKey="robotsTxt.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:robotsTxt" )
			, link  = event.buildAdminLink( linkTo="robotsTxt" )
		);
	}

	public any function index( event, rc, prc ) {
		prc.formId       = "robots_txt_"&createUUID();
		prc.formName     = "preside-objects.robots_txt.robots_txt";
		prc.formAction   = event.buildAdminLink( 'robotsTxt.fileUpdate' );
		prc.pageTitle    = translateResource( uri="cms:robotsTxt" );
		prc.pageSubtitle = translateResource( uri="cms:robotsTxt.subtitle" );
		prc.pageIcon     = "reddit-alien";
	}


	public any function fileUpdate( event, rc, prc ) {
		var formName         = "preside-objects.robots_txt.robots_txt";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = "";
		var persist          = "";
		validationResult     = validateForm( formName = formName, formData = formData );

		if ( not validationResult.validated() ) {
			messageBox.error( translateResource( "cms:robotsTxt.validation.failed" ) );
			persist                  = formData;
			persist.validationResult = validationResult;
			setNextEvent( url = event.buildAdminLink( linkTo = "robotsTxt" ), persistStruct = persist );
		}

		var fileContent     = toBinary( toBase64( formData.fileContent ) );

		rootFolderStorageProvider.putObject( object = fileContent, path = "robots.txt" )
		messageBox.info( translateResource( uri = "cms:robotsTxt.saved" ) );
		setNextEvent( url = event.buildAdminLink( linkTo = "robotsTxt" ) );
	}
}