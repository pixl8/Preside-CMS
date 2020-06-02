component {

	private string function index( event, rc, prc, args={} ) {
		args.ajax        = true;
		args.object      = "multilingual_language";
		args.prefetchUrl = event.buildAdminLink( linkTo="multilingualContent.getLanguagesForAjaxPicker", querystring="cachebuster=#LCase( CreateUUId() )#" );
		args.remoteUrl   = event.buildAdminLink( linkTo="multilingualContent.getLanguagesForAjaxPicker", querystring="cachebuster=#LCase( CreateUUId() )#&q=%QUERY" );

		return renderViewlet( event="formcontrols.objectPicker.index", args=args );
	}

}