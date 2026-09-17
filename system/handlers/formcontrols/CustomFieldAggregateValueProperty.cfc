/**
 * @feature presideForms and customFields
 */
component {

	public string function index( event, rc, prc, args={} ) {
		args.prefetchUrl = event.buildAdminLink(
			  linkTo      = "customFields.fetchAggregateValueProperties"
			, queryString = "cacheBuster=#CreateUUId()#"
		);
		args.remoteUrl = event.buildAdminLink(
			  linkTo      = "customFields.fetchAggregateValueProperties"
			, queryString = "cacheBuster=#CreateUUId()#&q=%QUERY"
		);

		return renderView( view="/formcontrols/objectPicker/index", args=args );
	}

}
