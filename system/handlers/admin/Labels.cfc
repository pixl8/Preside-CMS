component {

	property name="labelRendererService" inject="LabelRendererService";

	private string function render( event, rc, prc, struct args={} ) {
		var labelRenderer = arguments.args.labelRenderer ?: "";

		return labelRendererService.renderLabel( labelRenderer=labelRenderer, args=arguments.args );
	}

	public void function renderJson( event, rc, prc ) {
		var labelRenderer = rc.labelRenderer ?: "";
		var result = {
			label = labelRendererService.renderLabel( labelRenderer=labelRenderer, args=rc )
		};

		event.renderData( type="json", data=result );
	}
}