component {

	property name="labelRendererService" inject="LabelRendererService";

	public void function render( event, rc, prc ) {
		var objectName = rc.objectName ?: "";
		var result     = { label="object_name_required" };

		if ( len( objectName ) ) {
			result.label = labelRendererService.renderLabel( objectName, rc );
		}

		event.renderData( type="json", data=result );
	}
}