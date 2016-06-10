component {

	property name="auditService" inject="auditService";

	public string function index( event, rc, prc, args={} ) output=false {
		var actions = auditService.getLoggedActions();

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var action in actions ){
			args.labels.append( translateResource( uri="cms:auditTrail.#action#.title", defaultValue=action ) );
			args.values.append( action );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}