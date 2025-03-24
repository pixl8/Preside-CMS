/**
 * @feature formbuilder2
 */
component {

	private array function _selectFields( event, rc, prc ) {
		return [
			  "formbuilder_question.field_label"
		];
	}

	private string function _renderLabel( required string field_label ) {
		return arguments.field_label;
	}

}