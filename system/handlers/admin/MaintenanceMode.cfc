component extends="preside.system.base.AdminHandler" {

	property name="maintenanceModeManagerService" inject="maintenanceModeManagerService";
	property name="messageBox"                    inject="coldbox:plugin:messagebox";

	public void function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !hasCmsPermission( "maintenanceMode.configure" ) ) {
			event.adminAccessDenied();
		}

		prc.pageIcon = "medkit";

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:maintenanceMode" )
			, link  = event.buildAdminLink( linkTo="maintenanceMode" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle = translateResource( "cms:maintenanceMode" );
		prc.settings  = maintenanceModeManagerService.getSettings();
	}

	public void function saveSettingsAction( event, rc, prc ) {
		var formName         = "maintenance-mode.settings";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( !validationResult.validated() ) {
			var persist = formData;
			persist.validationResult = validationResult;
			messageBox.error( translateResource( uri="cms:maintenanceMode.settingsform.error" ) );
			setNextEvent( url=event.buildAdminLink( linkTo="maintenanceMode" ), persistStruct=persist );
		}

		maintenanceModeManagerService.saveSettings( formData );
		messageBox.info( translateResource( uri="cms:maintenanceMode.settings.saved.confirmation" ) );
		setNextEvent( url=event.buildAdminLink( linkTo="maintenanceMode" ) );
	}

}