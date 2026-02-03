/**
 * @feature admin
 */
component {

	public string function writeText(
		  required string  text
		,          string  type    = ""
		,          string  style   = ""
		,          boolean bold    = false
		,          boolean italic  = false
		,          any     newLine = false
	) {
		return _styleText( argumentCollection=arguments ) & newLines( arguments.newLine );
	}

	public string function writeLine(
		  required numeric length
		,          string  type      = ""
		,          string  style     = ""
		,          string  character = "-"
		,          any     newLine   = true
	) {
		return _styleText( text=RepeatString( arguments.character, arguments.length ), type=arguments.type, style=arguments.style ) & newLines( arguments.newLine );
	}

	public string function writeTable(
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
				var bold = false;

				if ( IsSimpleValue( cell ) ) {
					text = cell;
				} else {
					text = cell.text ?: "";
					type = cell.type ?: "";
					bold = cell.bold ?: false;
				}

				textTable &= writeText(
					  text = " " & text & " " & RepeatString( " ", colsWidth[ j ] - Len( text ) )
					, type = type
					, bold = bold
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

	public string function newLines( any newLine=true ) {
		if ( isNumeric( arguments.newLine ) ) {
			return RepeatString( newLine(), arguments.newLine );
		} else if ( isBoolean( arguments.newLine ) && arguments.newLine ) {
			return newLine();
		}
		return "";
	}

	private string function _styleText(
		  string  text   = ""
		, string  type   = ""
		, string  style  = ""
		, boolean bold   = false
		, boolean italic = false
	) {
		var type   = Trim( arguments.type );
		var styles = {
			  info    = "white"
			, error   = "red"
			, warn    = "orange"
			, success = "green"
			, help    = "lightblue"
		};

		var textBold   = arguments.bold   ? "b" : "";
		var textItalic = arguments.italic ? "i" : "";
		var textColour = Len( type ) && StructKeyExists( styles, type ) ? ";#styles[ type ]#;" : "";
		var textStyles = Len( arguments.style ) ? arguments.style : textBold & textItalic & textColour;

		return Len( Trim( textStyles ) ) ? "[[#textStyles#]" & arguments.text & "]" : arguments.text;
	}

}