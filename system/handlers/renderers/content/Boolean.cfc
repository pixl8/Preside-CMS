component output=false {

	public boolean function default( event, rc, prc, args={} ){
		return IsTrue( args.data ?: "" );
	}

	public string function admin( event, rc, prc, args={} ){
		var data  = args.data ?: "";
		var yesNo = LCase( YesNoFormat( IsBoolean( data ) and data ) );
		var icon  = IsBoolean( data ) and data ? "check-circle green" : "times-circle red";

		return '<i class="fa fa-#icon#" title="#translateResource( "cms:boolean.#yesNo#" )#"></i>';
	}

}