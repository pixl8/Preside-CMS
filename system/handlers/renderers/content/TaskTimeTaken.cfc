component {

	public string function default( event, rc, prc, args={} ){
		var data    = Val( args.data ?: "" );

		if ( data < 0 ) {
			return '<em class="unknown">unknown</em>';
		}

		if ( data < 1000 ) {
			return "< 1s"
		}

		data = data \ 1000;
		if ( data < 60 ) {
			return NumberFormat( data ) & "s";
		}

		data = data \ 60;
		if ( data < 60 ) {
			return NumberFormat( data ) & "m";
		}

		data = data \ 60;
		if ( data < 24 ) {
			return NumberFormat( data ) & "h";
		}

		data = data \ 24;
		return NumberFormat( data ) & "d";
	}

	public string function accurate( event, rc, prc, args={} ){
		var data    = Val( args.data ?: "" );
		var minutes = 0;
		var seconds = 0;

		if ( data < 0 ) {
			return '<em class="unknown">unknown</em>';
		}

		if ( data < 1000 ) {
			return "< 1s"
		}

		data = data \ 1000;
		if ( data < 60 ) {
			return NumberFormat( data ) & "s";
		}

		seconds = data mod 60;
		data    = data \ 60;
		if ( data < 60 ) {
			return NumberFormat( data ) & "m " & NumberFormat( seconds ) & "s";
		}

		minutes = data mod 60;
		data    = data \ 60;
		if ( data < 24 ) {
			return NumberFormat( data ) & "h " & NumberFormat( minutes ) & "m " & NumberFormat( seconds ) & "s";
		}

		data = data \ 24;
		return NumberFormat( data ) & "d";
	}

}