component output=false {

	public string function default( event, rc, prc, args={} ){
		var data    = Val( args.data ?: "" );

		if ( data < 0 ) {
			return '<em class="unknown">unknown</em>';
		}

		if ( data < 1000 ) {
			return "< 1s"
		}

		data = data / 1000;
		if ( data < 60 ) {
			return NumberFormat( data ) & "s";
		}

		data = data / 60;
		if ( data < 60 ) {
			return NumberFormat( data ) & "m";
		}

		data = data / 60;
		if ( data < 24 ) {
			return NumberFormat( data ) & "h";
		}

		return "?";
	}

	public string function accurate( event, rc, prc, args={} ){
		var data      = Val( args.data ?: "" );
		var remainder = 0;

		if ( data < 0 ) {
			return '<em class="unknown">unknown</em>';
		}

		if ( data < 1000 ) {
			return "< 1s"
		}

		data = data / 1000;
		if ( data < 60 ) {
			return NumberFormat( data ) & "s";
		}

		remainder = data mod 60;
		data = data / 60;
		if ( data < 60 ) {
			return NumberFormat( data ) & "m " & NumberFormat( remainder ) & "s";
		}

		remainder = data mod 60;
		data = data / 60;
		if ( data < 24 ) {
			return NumberFormat( data ) & "h " & NumberFormat( data ) & "m " & NumberFormat( remainder mod 60 ) & "s";
		}
	}

}