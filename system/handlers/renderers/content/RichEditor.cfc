component output=false {
	property name="widgetsService"       inject="widgetsService";
	property name="assetRendererService" inject="assetRendererService";

	public string function default( event, rc, prc, viewletArgs={} ){
		var content = widgetsService.renderEmbeddedWidgets(
			richContent = ( viewletArgs.data ?: "" )
		);

		content = assetRendererService.renderEmbeddedImages( richContent=content, context="richeditor" );

		return content;
	}

}