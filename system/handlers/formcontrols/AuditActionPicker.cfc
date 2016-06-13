component {

	property name="auditService" inject="auditService";

	public string function index( event, rc, prc, args={} ) output=false {
		var actions = auditService.getLoggedActions();

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var action in actions ){
			args.labels.append( translateResource( uri="auditlog.#action.type#:#action.action#.title", defaultValue=action.action ) );
			args.values.append( action.action );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}