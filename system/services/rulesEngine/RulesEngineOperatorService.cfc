/**
 * Provides methods for comparing data using a configured operator
 *
 * @autodoc
 * @singleton
 *
 */
component displayName="RulesEngine Operator Service" {

// CONSTRUCTOR
	public any function init() {
		return this;
	}

// PUBLIC API
	/**
	 * Returns true or false based on the comparison
	 * of two strings + the supplied operator. Valid
	 * operators are: `eq`, `neq`, `contains`, `startswith`
     * and `endswith`.
	 *
	 * @autodoc
	 * @leftHandSide.hint  String for the left hand side of the expression
	 * @operator.hint      Operator to use
	 * @rightHandSide.hint String for the right hand side of the expression
	 */
	public boolean function compareStrings(
		  required string leftHandSide
		, required string operator
		, required string rightHandSide
	) {
		switch( arguments.operator ) {
			case "eq":
				return leftHandSide == rightHandSide;
			case "neq":
				return leftHandSide != rightHandSide;
			case "contains":
				return leftHandSide.findNoCase( rightHandSide ) > 0;
			case "notcontains":
				return !leftHandSide.findNoCase( rightHandSide ) > 0;
			case "startsWith":
				return leftHandSide.left( rightHandSide.len() ) == rightHandSide;
			case "notStartsWith":
				return !leftHandSide.left( rightHandSide.len() ) == rightHandSide;
			case "endsWith":
				return leftHandSide.right( rightHandSide.len() ) == rightHandSide;
			case "notendsWith":
				return !leftHandSide.right( rightHandSide.len() ) == rightHandSide;
		}

		return false;
	}

	/**
	 * Returns true or false based on the comparison
	 * of two numbers + the supplied operator. Valid
	 * operators are: `eq`, `neq`, `lt`, `lte`, `gt`
     * and `gte`.
	 *
	 * @autodoc
	 * @leftHandSide.hint  Number for the left hand side of the expression
	 * @operator.hint      Operator to use
	 * @rightHandSide.hint Number for the right hand side of the expression
	 */
	public boolean function compareNumbers(
		  required numeric leftHandSide
		, required string  operator
		, required numeric rightHandSide
	) {
		switch( arguments.operator ) {
			case "eq":
				return leftHandSide == rightHandSide;
			case "neq":
				return leftHandSide != rightHandSide;
			case "gt":
				return leftHandSide > rightHandSide;
			case "gte":
				return leftHandSide >= rightHandSide;
			case "lt":
				return leftHandSide < rightHandSide;
			case "lte":
				return leftHandSide <= rightHandSide;
		}

		return false;
	}

}

