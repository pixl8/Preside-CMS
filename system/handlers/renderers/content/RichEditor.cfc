component output=false {
	property name="widgetsService"       inject="widgetsService";
	property name="assetRendererService" inject="assetRendererService";

	public string function default( event, rc, prc, viewletArgs={} ){
		var content = ( viewletArgs.data ?: "" );

		content = widgetsService.renderEmbeddedWidgets( richContent = content );
		content = assetRendererService.renderEmbeddedImages( richContent=content, context="richeditor" );
		content = assetRendererService.renderEmbeddedAttachments( richContent=content, context="richeditor" );

		return content;
	}

}