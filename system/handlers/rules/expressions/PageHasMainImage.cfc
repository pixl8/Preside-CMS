/**
 * Expression handler for "Current page has/does not have a main image"
 *
 */
component {

	/**
	 * @expression true
	 * @expressionContexts webrequest,page
	 */
	private boolean function webRequest(
		  boolean _has = true
	) {
		var hasImage = Len( Trim( payload.page.main_image ?: "" ) );

		return _has ? hasImage : !hasImage;
	}

}