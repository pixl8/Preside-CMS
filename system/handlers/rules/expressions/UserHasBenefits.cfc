/**
 * Expression handler for "User has/has not all/any of the following benefits: {benefit list}"
 *
 */
component {

	/**
	 * @expression         true
	 * @benefits.fieldType object
	 * @benefits.object    website_benefit
	 */
	private boolean function webRequest(
		  required string  benefits
		,          boolean _has=true
		,          boolean _all=true
	) {
		return true; // TODO
	}

}