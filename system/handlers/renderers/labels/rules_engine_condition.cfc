component {

	private array function _selectFields( event, rc, prc ) {
		return [
			    "condition_name"
			  , "is_locked"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "condition_name";
	}

	private string function _renderLabel( event, rc, prc, string condition_name="", string is_locked=false ) {
		var iconClass = IsTrue( arguments.is_locked ) ? "fa-lock red" : "fa-lock-open light-grey"

		return '<i class="fa fa-fw #iconClass#"></i>&nbsp; #arguments.condition_name#';
	}

}