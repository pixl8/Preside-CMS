/**
 * Renders the coloured badges used by custom field conditional labels and boolean display options.
 *
 * @singleton      true
 * @presideService true
 * @autodoc        true
 * @feature        customFields
 */
component {

	public any function init() {
		return this;
	}

	public string function renderBadge( required string label, string colour="" ) {
		var label = Trim( arguments.label );

		if ( !Len( label ) ) {
			return "";
		}

		var colour = cssColour( arguments.colour );

		if ( !ReFindNoCase( "^(##[0-9a-f]{3,6}|[a-z]+)$", colour ) ) {
			return '<span class="badge">#EncodeForHTML( label )#</span>';
		}

		return '<span class="badge" style="background-color:#colour#;color:#contrastingTextColour( colour )#;">#EncodeForHTML( label )#</span>';
	}

	public string function cssColour( required string colour ) {
		var value = Trim( arguments.colour );

		switch( LCase( value ) ) {
			case "default": return "##999999";
			case "danger" : return "##d9534f";
			case "warning": return "##f0ad4e";
			case "success": return "##5cb85c";
			case "info"   : return "##5bc0de";
		}

		if ( ReFindNoCase( "^[0-9a-f]{3,6}$", value ) ) {
			return "##" & value;
		}

		return value;
	}

	public string function contrastingTextColour( required string colour ) {
		var hex = ReReplace( arguments.colour, "[^0-9A-Fa-f]", "", "all" );

		if ( Len( hex ) == 3 ) {
			hex = Mid( hex, 1, 1 ) & Mid( hex, 1, 1 ) & Mid( hex, 2, 1 ) & Mid( hex, 2, 1 ) & Mid( hex, 3, 1 ) & Mid( hex, 3, 1 );
		}
		if ( Len( hex ) != 6 ) {
			return "##fff";
		}

		var yiq = (
			  ( InputBaseN( Mid( hex, 1, 2 ), 16 ) * 299 )
			+ ( InputBaseN( Mid( hex, 3, 2 ), 16 ) * 587 )
			+ ( InputBaseN( Mid( hex, 5, 2 ), 16 ) * 114 )
		) / 1000;

		return yiq >= 128 ? "##333" : "##fff";
	}

}
