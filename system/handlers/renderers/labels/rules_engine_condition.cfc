component {

	private array function _selectFields( event, rc, prc ) {
		return [
			  "condition_name"
			, "is_locked"
			, "kind"
			, "applies_to"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "condition_name";
	}

	private string function _renderLabel( event, rc, prc, string condition_name="", string is_locked=false, string kind="", string applies_to="" ) {
		var lockClass = IsTrue( arguments.is_locked ) ? "fa-lock red"    : "fa-lock-open light-grey";
		var typeClass = arguments.kind == "filter"    ? "fa-filter grey" : "fa-map-signs blue";

		var appliesTo = renderContent( renderer="rulesEngineAppliesTo", data={ data=arguments.applies_to, kind=arguments.kind }, context="picker" );

		return '<i class="fa fa-fw #lockClass#"></i><i class="fa fa-fw #typeClass#"></i> #arguments.condition_name# (#appliesTo# )';
	}

}