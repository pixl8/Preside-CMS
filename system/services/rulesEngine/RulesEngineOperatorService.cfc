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
			case "startsWith":
				return leftHandSide.lCase().startsWith( rightHandSide.lCase() );
			case "endsWith":
				return leftHandSide.lCase().endsWith( rightHandSide.lCase() );

		}

		return false;
	}

}

