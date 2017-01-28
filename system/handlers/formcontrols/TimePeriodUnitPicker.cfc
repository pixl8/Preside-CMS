component {

	private string function index( event, rc, prc, args={} ) {
		var pastOnly   = IsTrue( args.pastOnly   ?: "" );
		var futureOnly = IsTrue( args.futureOnly ?: "" );

		args.values = [ "yyyy", "m", "d", "h", "n" ];
		args.labels = [];

		for( var value in args.values ){
			args.labels.append( translateResource( "cms:time.period.unit.#value#" ) );
		}

		return renderView( view="/formControls/select/index", args=args );
	}

}