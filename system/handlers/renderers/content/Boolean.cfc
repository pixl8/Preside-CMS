component {

	public boolean function default( event, rc, prc, args={} ){
		return IsTrue( args.data ?: "" );
	}

	public string function admin( event, rc, prc, args={} ){
		var data  = args.data ?: "";

		if ( IsBoolean( data ) ) {
			var yesNo = LCase( YesNoFormat( data ) );
			var icon  = data ? "check-circle green" : "times-circle red";

			return '<i class="fa fa-#icon#" title="#translateResource( "cms:boolean.#yesNo#" )#"></i>';
		}

		return '<i class="fa fa-question grey" title="#translateResource( "cms:boolean.not.set" )#"></i>';
	}

}