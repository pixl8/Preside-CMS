/**
 *
 * @feature emailCenter
 */
component {
	property name="emailTemplateService" inject="emailTemplateService";

	private string function renderHtmlSnippet( event, rc, prc, args={} ) {
		return emailTemplateService.renderHtmlSnippet( argumentCollection=args );
	}
}