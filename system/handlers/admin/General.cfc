component {

	property name="loginService"         inject="loginService";
	property name="updateManagerService" inject="updateManagerService";
	property name="i18n"                 inject="coldbox:plugin:i18n";

	public void function setLocale( event, rc, prc ) {
		var locale = rc.locale ?: "";

		if ( Len( Trim( locale ) ) ) {
			i18n.setFwLocale( locale );
		}

		var redirectUrl = Len( Trim( cgi.http_referer ) ) ? cgi.http_referer : event.buildAdminLink();

		setNextEvent( url=redirectUrl );
	}

	public void function toggleNonLiveContent( event, rc, prc ) {
 		var redirectUrl = Len( Trim( cgi.http_referer ) ) ? cgi.http_referer : event.buildLink( page="homepage" );

 		loginService.toggleShowNonLiveContent();

		setNextEvent( url=redirectUrl );
	}

// viewlets
	private string function footer( event, rc, prc, args={} ) {
		args.isGitClone     = updateManagerService.isGitClone();

		args.currentVersion = args.isGitClone ? updateManagerService.getGitBranch() : updateManagerService.getCurrentVersion();

		return renderView( view="/admin/general/footer", args=args );
	}
}