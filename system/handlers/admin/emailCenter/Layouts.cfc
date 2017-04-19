component extends="preside.system.base.AdminHandler" {

	property name="emailLayoutService" inject="emailLayoutService";
	property name="messagebox"         inject="coldbox:plugin:messagebox";

	public void function preHandler( event, action, eventArguments ) {
		super.preHandler( argumentCollection=arguments );

		if ( !isFeatureEnabled( "emailcenter" ) ) {
			event.notFound();
		}


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
			, blueprint     = ""
			, type          = "html"
			, subject       = "Test email subject"
			, body          = "<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>"
		);
		prc.preview.text = emailLayoutService.renderLayout(
			  layout        = layoutId
			, emailTemplate = ""
			, blueprint     = ""
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

		if ( !hasCmsPermission( "emailcenter.layouts.configure" ) ) {
			event.adminAccessDenied();
		}

		prc.configForm = renderViewlet( event="admin.emailCenter.layouts._configForm", args={
			  layoutId   = layoutId
			, formAction = event.buildAdminLink( linkTo='emailcenter.layouts.saveConfigurationAction' )
		} );

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

		if ( !hasCmsPermission( "emailcenter.layouts.configure" ) ) {
			event.adminAccessDenied();
		}

		runEvent(
			  event          = "admin.emailCenter.layouts._saveConfiguration"
			, private        = true
			, prepostExempt  = true
			, eventArguments = {
				  successUrl = event.buildAdminLink( linkto="emailcenter.layouts.layout", queryString="layout=" & layoutId )
				, failureUrl = event.buildAdminLink( linkto="emailcenter.layouts.configure", queryString="layout=" & layoutId )
				, layoutId   = layoutId
			  }
		);
	}

// VIEWLETS & HELPER ACTIONS
	private string function _configForm( event, rc, prc, args={} ) {
		var layoutId   = args.layoutId   ?: "";
		var templateId = args.templateId ?: "";
		var blueprint  = args.blueprint  ?: "";

		args.layoutFormName = emailLayoutService.getLayoutConfigFormName( layoutId );
		args.savedConfig    = emailLayoutService.getLayoutConfig(
			  layout        = layoutId
			, emailTemplate = templateId
			, blueprint     = blueprint
			, merged        = false
		);

		return renderView( view="/admin/emailcenter/layouts/_configForm", args=args );
	}

	private void function _saveConfiguration(
		  required string layoutId
		, required string successUrl
		, required string failureUrl
		,          string templateId = ""
		,          string blueprint  = ""
	) {
		/*
		   TODO: make this work for template saving too
		*/

		var formName         = emailLayoutService.getLayoutConfigFormName( layoutId );
		var formData         = event.getCollectionForForm( formName );

		if ( Len( Trim( arguments.templateId ) & Trim( arguments.blueprint ) ) ) {
			for( var setting in formData ){
				if ( IsFalse( rc[ "_override_" & setting ] ?: "" ) ) {
					formData.delete( setting );
				}
			}
		}

		var validationResult = validateForm( formName, formData );
		if ( validationResult.validated() ) {
			emailLayoutService.saveLayoutConfig(
				  layout        = layoutId
				, emailTemplate = templateId
				, blueprint     = blueprint
				, config        = formData
			);

			if ( Len( Trim( arguments.templateId ) ) ) {
				event.audit(
					  action   = "save_template_layout_configuration"
					, type     = "emailtemplate"
					, recordId = templateId
					, detail   = formData
				);
				messagebox.info( translateResource( "cms:emailcenter.systemTemplates.layout.configuration.saved.message") );
			} elseif ( Len( Trim( arguments.blueprint ) ) ) {
				event.audit(
					  action   = "save_blueprint_layout_configuration"
					, type     = "emailblueprints"
					, recordId = blueprint
					, detail   = formData
				);
				messagebox.info( translateResource( "cms:emailcenter.blueprints.layout.configuration.saved.message") );
			} else {
				event.audit(
					  action   = "save_email_layout"
					, type     = "emaillayout"
					, recordId = layoutId
					, detail   = formData
				);
				messagebox.info( translateResource( "cms:emailcenter.layouts.configuration.saved.message") );
			}


			setNextEvent( url=arguments.successUrl );
		}

		var persist = formdata;
		persist.validationResult = validationResult;
		messageBox.error( translateResource( "cms:datamanager.data.validation.error" ) );
		setNextEvent( url=arguments.failureUrl, persistStruct=persist );
	}
}