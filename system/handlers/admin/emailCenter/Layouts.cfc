component extends="preside.system.base.AdminHandler" {

	property name="emailLayoutService" inject="emailLayoutService";
	property name="messagebox"         inject="coldbox:plugin:messagebox";

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !hasCmsPermission( "emailcenter.layouts.navigate" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:emailcenter.layouts.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts" )
		);

		event.setValue( "pageIcon", "envelope", true );
	}

	public void function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:emailcenter.layouts.page.title"    );
		prc.pageSubTitle = translateResource( "cms:emailcenter.layouts.page.subTitle" );

		prc.layouts = emailLayoutService.listLayouts();
	}

	public void function layout( event, rc, prc ) {
		var layoutId = rc.layout ?: "";
		prc.layout = emailLayoutService.getLayout( layoutId );
		if ( !prc.layout.count() ) {
			event.adminNotFound();
		}

		prc.pageTitle    = translateResource( uri="cms:emailcenter.layouts.layout.page.title"   , data=[ prc.layout.title ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.layouts.layout.page.subTitle", data=[ prc.layout.title ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.layouts.layout.breadcrumb.title"  , data=[ prc.layout.title ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts.layout", queryString="layout=" & layoutId )
		);

		prc.preview = {};
		prc.preview.html = emailLayoutService.renderLayout(
			  layout        = layoutId
			, emailTemplate = ""
			, type          = "html"
			, subject       = "Test email subject"
			, body          = "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>"
		);
		prc.preview.text = emailLayoutService.renderLayout(
			  layout        = layoutId
			, emailTemplate = ""
			, type          = "text"
			, subject       = "Test email subject"
			, body          = "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
		);
	}

	public void function configure( event, rc, prc ) {
		var layoutId = rc.layout ?: "";
		prc.layout = emailLayoutService.getLayout( layoutId );
		if ( !prc.layout.count() ) {
			event.adminNotFound();
		}

		prc.layoutFormName = emailLayoutService.getLayoutConfigFormName( layoutId );
		prc.savedConfig    = emailLayoutService.getLayoutConfig( layoutId );

		prc.pageTitle    = translateResource( uri="cms:emailcenter.layouts.configure.page.title"   , data=[ prc.layout.title ] );
		prc.pageSubTitle = translateResource( uri="cms:emailcenter.layouts.configure.page.subTitle", data=[ prc.layout.title ] );

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.layouts.layout.breadcrumb.title"  , data=[ prc.layout.title ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts.layout", queryString="layout=" & layoutId )
		);
		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:emailcenter.layouts.configure.breadcrumb.title"  , data=[ prc.layout.title ] )
			, link  = event.buildAdminLink( linkTo="emailcenter.layouts.configure", queryString="layout=" & layoutId )
		);
	}

	public void function saveConfigurationAction( event, rc, prc ) {
		var layoutId = rc.layout ?: "";
		prc.layout = emailLayoutService.getLayout( layoutId );
		if ( !prc.layout.count() ) {
			event.adminNotFound();
		}

		var formName         = emailLayoutService.getLayoutConfigFormName( layoutId );
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( validationResult.validated() ) {
			emailLayoutService.saveLayoutConfig(
				  layout = layoutId
				, config = formData
			);

			event.audit(
				  action   = "save_email_layout"
				, type     = "emaillayout"
				, recordId = layoutId
				, detail   = formData
			);

			messagebox.info( translateResource( "cms:emailcenter.layouts.configuration.saved.message") );

			setNextEvent( url=event.buildAdminLink( linkto="emailcenter.layouts.layout", queryString="layout=" & layoutId ) );
		}

		var persist = formdata;
		persist.validationResult = validationResult;
		messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent( url=event.buildAdminLink( linkto="emailcenter.layouts.configure", queryString="layout=" & layoutId ), persistStruct=persist );
	}
}