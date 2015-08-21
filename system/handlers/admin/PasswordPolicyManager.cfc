component extends="preside.system.base.AdminHandler" {

	property name="passwordPolicyService"    inject="passwordPolicyService";
	property name="passwordStrengthAnalyzer" inject="passwordStrengthAnalyzer";
	property name="messagebox"               inject="coldbox:plugin:messagebox";

// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) {
		super.preHandler( argumentCollection = arguments );

		if ( !isFeatureEnabled( "passwordPolicyManager" ) ) {
			event.notFound();
		}

		if ( !hasCmsPermission( permissionKey="passwordPolicyManager.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:passwordPolicyManager.breadcrumb.title" )
			, link  = event.buildAdminLink( linkTo="passwordPolicyManager" )
		);

		prc.pageIcon = "key";
	}

// EVENTS
	function index( event, rc, prc ) {
		prc.pageTitle    = translateResource( "cms:passwordPolicyManager.page.title" );
		prc.pageSubTitle = translateResource( "cms:passwordPolicyManager.page.subtitle" );

		prc.policyContexts = passwordPolicyService.listContexts();
		prc.currentContext = rc.context ?: "cms";

		if ( !prc.policyContexts.findNoCase( prc.currentContext ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="passwordPolicyManager" ) );
		}

		prc.savedPolicy = passwordPolicyService.getPolicy( prc.currentContext );

		event.setView( "/admin/passwordPolicyManager/index" );
	}

	function editPolicyAction( event, rc, prc ) {
		var policyContexts   = passwordPolicyService.listContexts();
		var context          = rc.context ?: "";

		if ( !policyContexts.findNoCase( context ) ) {
			setNextEvent( url=event.buildAdminLink( linkto="passwordPolicyManager" ) );
		}

		var formName         = "preside-objects.password_policy.admin.edit";
		var formData         = event.getCollectionForForm( formName );
		var validationResult = validateForm( formName, formData );

		if ( validationResult.validated() ) {
			passwordPolicyService.savePolicy( argumentCollection=formData, context=context );
			messagebox.info( translateResource( "cms:passwordpolicymanager.policy.saved.confirmation" ) );
		} else {
			messagebox.info( translateResource( "cms:passwordpolicymanager.policy.validation.failed.message" ) );
		}

		setNextEvent( url=event.buildAdminLink( linkto="passwordPolicyManager", queryString="context=" & context ) );
	}

	function strengthReport( event, rc, prc ) {
		if ( !Len( Trim( rc.password ?: "" ) ) ) {
			event.renderData( data={
				  score       = 0
				, name        = ""
				, title       = ""
				, description = ""
			}, type="json" );
		} else {
			var score     = passwordStrengthAnalyzer.calculatePasswordStrength( rc.password ?: "" );
			var scoreName = passwordPolicyService.getStrengthNameForScore( score );

			event.renderData( data={
				  score       = score
				, name        = scoreName
				, title       = translateResource( "cms:password.strength.#scoreName#.title" )
				, description = translateResource( "cms:password.strength.#scoreName#.description" )
			}, type="json" );
		}
	}

}