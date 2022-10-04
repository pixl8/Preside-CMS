component {

	public string function writeText(
		  required string  text
		,          string  type    = ""
		,          boolean bold    = false
		,          boolean newLine = false
	) {
		return _styleText( argumentCollection=arguments ) & ( arguments.newLine ? newLine() : "" );
	}

	public string function writeLine(
		  required numeric length
		,          string  type      = ""
		,          string  character = "-"
		,          boolean newLine   = true
	) {
		return _styleText( text=RepeatString( arguments.character, arguments.length ), type=arguments.type ) & ( arguments.newLine ? newLine() : "" );
	}

	public string function newLine() {
		return Chr( 10 );
	}

	public string function newTable(
		  required array header
		,          array rows = []
	) {
		var colsCount = ArrayLen( arguments.header );
		var rowsCount = 0;
		var colsWidth = [];
		var textTable = "";

		ArrayPrepend( arguments.rows, arguments.header );

		rowsCount = ArrayLen( arguments.rows );

		for ( var i=1; i<=colsCount; i++ ) {
			for ( var row in arguments.rows ) {
				var cell = row[ i ];
				var text = "";

				if ( IsSimpleValue( cell ) ) {
					text = cell;
				} else {
					text = cell.text ?: "";
				}

				var colLen = Len( Trim( text ) );

				if ( !ArrayIsDefined( colsWidth, i ) || colLen > colsWidth[ i ] ) {
					colsWidth[ i ] = colLen;
				}
			}
		}

		var headerText = "";
		for ( var i=1; i<=rowsCount; i++ ) {
			var type = arguments.rows[ i ][ colsCount + 1 ] ?: "";

			for ( var j=1; j<=colsCount; j++ ) {
				var cell = arguments.rows[ i ][ j ];
				var text = "";
				var type = "";

				if ( IsSimpleValue( cell ) ) {
					text = cell;
				} else {
					text = cell.text ?: "";
					type = cell.type ?: "";
				}

				textTable &= writeText(
					  text = " " & text & " " & RepeatString( " ", colsWidth[ j ] - Len( text ) )
					, type = type
				);
			}

			textTable &= newLine();

			if ( i == 1 ) {
				headerText = textTable;
				textTable &= writeLine( length=Len( headerText ), character="=" );
			}
		}

		textTable &= writeLine( length=Len( headerText ), character="-" );

		return textTable;
	}

	private string function _styleText(
		  string  text = ""
		, string  type = ""
		, boolean bold = false
	) {
		var styles = {
			  info    = "white"
			, error   = "red"
			, warn    = "orange"
			, success = "green"
		}

		var textBold   = arguments.bold                ? "b"                            : "";
		var textColour = Len( Trim( arguments.type ) ) ? ";#styles[ arguments.type ]#;" : "";

		return Len( Trim( arguments.type ) ) ? "[[#textBold##textColour#]" & arguments.text & "]" : arguments.text;
	}

}