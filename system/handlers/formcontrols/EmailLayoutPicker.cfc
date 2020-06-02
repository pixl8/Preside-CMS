component {

	property name="emailLayoutService" inject="emailLayoutService";

	public string function index( event, rc, prc, args={} ) output=false {
		var layouts = emailLayoutService.listLayouts();

		args.values = [ "" ];
		args.labels = [ "" ];

		for( var layout in layouts ){
			args.values.append( layout.id );
			args.labels.append( layout.title );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}