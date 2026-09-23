/**
 * @feature admin and customFields
 */
component {

	property name="customFieldsService" inject="customFieldsService";

	public string function admin( event, rc, prc, args={} ) {
		return index( argumentCollection=arguments );
	}

	public string function adminView( event, rc, prc, args={} ) {
		return index( argumentCollection=arguments );
	}

	public string function index( event, rc, prc, args={} ) {
		var rules    = _rulesFromArgs( argumentCollection=arguments );
		var rendered = [];

		for( var rule in rules ) {
			var label = EncodeForHTML( rule.label_text ?: "" );

			if ( !Len( label ) ) {
				continue;
			}

			var colour = _cssColour( rule.colour ?: ( rule.style ?: "" ) );
			if ( !Len( colour ) ) {
				ArrayAppend( rendered, '<span class="badge">#label#</span>' );
			} else {
				ArrayAppend( rendered, '<span class="badge" style="background-color:#EncodeForHTMLAttribute( colour )#;color:#EncodeForHTMLAttribute( _contrastingTextColour( colour ) )#;">#label#</span>' );
			}
		}

		return ArrayToList( rendered, " " );
	}

	private array function _rulesFromArgs( event, rc, prc, args={} ) {
		if ( ( args.objectName ?: "" ) == "custom_field_conditional_rule" ) {
			if ( IsStruct( args.record ?: "" ) && !StructIsEmpty( args.record ) ) {
				return [ args.record ];
			}

			return [ { label_text=args.data ?: "" } ];
		}

		var rules = [];

		for( var ruleId in customFieldsService.evaluateConditionalLabels( args.data ?: "" ) ) {
			var rule = customFieldsService.getConditionalRuleById( ruleId );
			if ( !StructIsEmpty( rule ) ) {
				ArrayAppend( rules, rule );
			}
		}

		return rules;
	}

	private string function _cssColour( required string colour ) {
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

	private string function _contrastingTextColour( required string colour ) {
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
