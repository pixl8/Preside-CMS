component {

	property name="updateManagerService" inject="updateManagerService";

	public void function toggleShowDrafts( event, rc, prc ) {
 		var redirectUrl = Len( Trim( cgi.http_referer ) ) ? cgi.http_referer : event.buildLink( page="homepage" );

 		loginService.toggleShowDrafts();

		setNextEvent( url=redirectUrl );
	}

// viewlets
	private string function footer( event, rc, prc, args={} ) {
		args.isGitClone     = updateManagerService.isGitClone();

		args.currentVersion = args.isGitClone ? updateManagerService.getGitBranch() : updateManagerService.getCurrentVersion();

		return renderView( view="/admin/general/footer", args=args );
	}
}