component {

	property name="auditService" inject="auditService";

	public string function index( event, rc, prc, args={} ) output=false {
		var actions = auditService.getLoggedActions();
		var actionsWithTitles = [];

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var action in actions ){
			actionsWithTitles.append({
				  label = translateResource( uri="auditlog.#action.type#:#action.action#.title", defaultValue=action.action )
				, value = action.action
			});
		}

		actionsWithTitles.sort( function( a, b ){
			return a.label < b.label ? -1 : 1;
		} );

		for( var action in actionsWithTitles ){
			args.labels.append( action.label );
			args.values.append( action.value );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}