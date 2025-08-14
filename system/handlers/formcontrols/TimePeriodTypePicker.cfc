/**
 * @feature presideForms
 */
component {

	private string function index( event, rc, prc, args={} ) {
		var pastOnly   = IsTrue( args.pastOnly   ?: "" );
		var futureOnly = IsTrue( args.futureOnly ?: "" );

		args.values = [ "alltime", "between", "equal" ];
		args.labels = [];

		if ( !futureOnly ) {
			ArrayAppend( args.values, [ "recent", "since", "before", "past", "pastminus", "pastequal", "yesterday", "lastweek", "lastmonth", "lastyear" ], true  );
		}

		ArrayAppend( args.values, [ "today", "thisweek", "thismonth", "thisyear" ], true );

		if ( !pastOnly ) {
			ArrayAppend( args.values, [ "upcoming", "until", "after", "future", "futureplus", "futureequal", "tomorrow", "nextweek", "nextmonth", "nextyear" ], true );
		}

		for( var value in args.values ){
			ArrayAppend( args.labels, translateResource( "cms:time.period.type.#value#.label" ) );
		}

		return renderView( view="/formControls/select/index", args=args );
	}

}