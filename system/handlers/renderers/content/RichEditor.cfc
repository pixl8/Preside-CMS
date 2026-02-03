/**
 * @feature admin or cms
 */
component {
	property name="contentRendererService" inject="contentRendererService";

	public string function default( event, rc, prc, args={} ){
		var content = ( args.data ?: "" );

		content = contentRendererService.renderEmbeddedWidgets( richContent = content );
		content = contentRendererService.renderEmbeddedImages( richContent=content, context="richeditor" );
		content = contentRendererService.renderEmbeddedAttachments( richContent=content, context="richeditor" );
		content = contentRendererService.renderEmbeddedLinks( richContent=content );

		contentRendererService.renderCodeHighlighterIncludes( richContent=content );

		return content;
	}

	public string function adminView( event, rc, prc, args={} ) {
		return renderView( view="renderers/content/richeditor/adminView", args=args );
	}

	public string function email( event, rc, prc, args={} ){
		var content = ( args.data ?: "" );

		content = contentRendererService.renderEmbeddedWidgets(
			  richContent       = content
			, context           = "email"
			, postProcessor     = "email.renderHelper.renderHtmlSnippet"
			, postProcessorArgs = args
		);

		content = contentRendererService.renderEmbeddedImages(
			  richContent       = content
			, context           = "richeditor"
			, postProcessor     = "email.renderHelper.renderHtmlSnippet"
			, postProcessorArgs = args
		);
		content = contentRendererService.renderEmbeddedAttachments(
			  richContent       = content
			, context           = "richeditor"
			, postProcessor     = "email.renderHelper.renderHtmlSnippet"
			, postProcessorArgs = args
		);
		content = contentRendererService.renderEmbeddedLinks(
			  richContent       = content
			, postProcessor     = "email.renderHelper.renderHtmlSnippet"
			, postProcessorArgs = args
		);

		return content;
	}
}