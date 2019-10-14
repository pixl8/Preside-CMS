component extends="preside.system.base.AdminHandler" {

	property name="presideRestService" inject="presideRestService";

	public void function preHandler( event ) {
		super.preHandler( argumentCollection = arguments );

		_permissionsCheck( "navigate", event );

		prc.pageIcon = "fa-code";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:apiManager.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo = "apimanager" )
		);
	}

	public void function index( event, rc, prc ) {
		prc.apis = presideRestService.listApis();

		for( var i=prc.apis.len(); i>0; i-- ) {
			if ( IsTrue( prc.apis[ i ].hideFromManager ?: "" ) ) {
				prc.apis.deleteAt( i );
			}
		}


		prc.pageTitle    = translateResource( "cms:apiManager.page.title" );
		prc.pageSubTitle = translateResource( "cms:apiManager.page.subtitle" );

		prc.configLinkBase = event.buildAdminLink( linkto="apiManager.configureAuth", queryString="id={id}" );
	}

	public void function configureAuth( event, rc, prc ) {
		var api = rc.id ?: "";

		if ( !Len( Trim( api ) ) ) {
			event.notFound();
		}

		var authProvider = presideRestService.getAuthenticationProvider( api );

		if ( !Len( Trim( authProvider ) ) ) {
			event.notFound();
		}

		var viewlet = "rest.auth.#authProvider#.configure";

		if ( getController().viewletExists( viewlet ) ) {
			prc.body = renderViewlet( event=viewlet, args={ api=api } );
		} else {
			prc.body = renderView( view="/admin/apiManager/_noConfigurationForAuthProvider", args={ authProvider=authProvider } );
		}

		event.addAdminBreadCrumb(
			  title = translateResource( uri="cms:apiManager.configureauth.page.breadcrumbTitle", data=[ api ] )
			, link  = event.buildAdminLink( linkTo = "apimanager.configureAuth", queryString="id=#api#" )
		);
		prc.pageTitle    = translateResource( uri="cms:apiManager.configureauth.page.title", data=[ api ] );
		prc.pageSubTitle = translateResource( uri="cms:apiManager.configureauth.page.subtitle", data=[ api ] );
	}

	// PRIVATE UTILITY
	private void function _permissionsCheck( required string key, required any event ) {
		var permKey   = "apiManager." & arguments.key;
		var permitted = hasCmsPermission( permissionKey = permKey );

		if ( !permitted ) {
			event.adminAccessDenied();
		}
	}

}