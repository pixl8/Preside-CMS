component output=false {

	property name="siteTemplatesService" inject="siteTemplatesService";

	public string function index( event, rc, prc, args={} ) output=false {
		var templates = siteTemplatesService.listTemplates();

		args.values    = [ "" ];
		args.labels    = [ translateResource( "cms:sitetemplates.picker.no.template" ) ];

		if ( !templates.Len() ) {
			return "";
		}

		for( var template in templates ) {
			args.values.append( template.getId() );
			args.labels.append( translateResource( uri=template.getTitle(), defaultValue=template.getId() ) );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}