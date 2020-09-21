component {

	private array function _selectFields( event, rc, prc ) {
		return [
			  "formbuilder_question.field_id"
			, "formbuilder_question.field_label"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "formbuilder_question.field_label, formbuilder_question.field_id";
	}

	private string function _renderLabel( required string field_id, required string field_label ) {
		return arguments.field_label & " (<code>#arguments.field_id#</code>)";
	}

}