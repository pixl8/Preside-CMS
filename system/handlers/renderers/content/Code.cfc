component {

	private string function default( event, rc, prc, args={} ){
		var content = args.data ?: "";

		if ( Len( Trim( content ) ) ) {
			return "<code>#content#</code>";
		}

		return "";
	}

}