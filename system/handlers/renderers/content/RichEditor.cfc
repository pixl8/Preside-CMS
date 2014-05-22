component output=false {
	property name="contentRenderer" inject="contentRenderer";

	public string function default( event, rc, prc, viewletArgs={} ){
		var content = ( viewletArgs.data ?: "" );

		content = contentRenderer.renderEmbeddedWidgets( richContent = content );
		content = contentRenderer.renderEmbeddedImages( richContent=content, context="richeditor" );
		content = contentRenderer.renderEmbeddedAttachments( richContent=content, context="richeditor" );
		content = contentRenderer.renderEmbeddedLinks( richContent=content );

		return content;
	}

}