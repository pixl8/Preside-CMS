component output=false {
	property name="contentRendererService" inject="contentRendererService";

	public string function default( event, rc, prc, viewletArgs={} ){
		var content = ( viewletArgs.data ?: "" );

		content = contentRendererService.renderEmbeddedWidgets( richContent = content );
		content = contentRendererService.renderEmbeddedImages( richContent=content, context="richeditor" );
		content = contentRendererService.renderEmbeddedAttachments( richContent=content, context="richeditor" );
		content = contentRendererService.renderEmbeddedLinks( richContent=content );

		return content;
	}

}