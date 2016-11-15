component {

	property name="emailRecipientTypeService" inject="emailRecipientTypeService";

	public string function index( event, rc, prc, args={} ) output=false {
		var types = emailRecipientTypeService.listRecipientTypes();

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var type in types ){
			args.values.append( type.id );
			args.labels.append( type.title );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}