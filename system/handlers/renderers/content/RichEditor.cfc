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

}