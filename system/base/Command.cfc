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