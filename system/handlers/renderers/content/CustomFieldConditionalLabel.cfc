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
		var encoded = args.data ?: "";
		var ruleId  = customFieldsService.evaluateConditionalLabel( encoded );
		if ( !Len( Trim( ruleId ) ) ) {
			return "";
		}

		var rule  = customFieldsService.getConditionalRuleById( ruleId );
		var style = rule.style ?: "default";
		var icon  = Len( Trim( rule.icon ?: "" ) ) ? '<i class="fa fa-fw #rule.icon#"></i> ' : "";
		var label = EncodeForHTML( rule.label_text ?: "" );

		return '<span class="badge badge-#EncodeForHTMLAttribute( style )#">#icon##label#</span>';
	}

}
