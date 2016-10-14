component {

	private string function index( event, rc, prc, args={} ) {
		var pastOnly   = IsTrue( args.pastOnly   ?: "" );
		var futureOnly = IsTrue( args.futureOnly ?: "" );

		args.values = [ "alltime", "between" ];
		args.labels = [];

		if ( !futureOnly ) {
			args.values.append( [ "recent", "since", "before" ], true );
		}
		if ( !pastOnly ) {
			args.values.append( [ "upcoming", "until", "after" ], true );
		}

		for( var value in args.values ){
			args.labels.append( translateResource( "cms:time.period.type.#value#.label" ) );
		}

		return renderView( view="/formControls/select/index", args=args );
	}

}