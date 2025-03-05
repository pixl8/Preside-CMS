component {
	private array function _selectFields( event, rc, prc ) {
		return [
			  "email_template.name   as template_name"
			, "email_blueprint.name  as blueprint_name"
			, "item"
		];
	}

	private string function _renderLabel( event, rc, prc ) {
		var template_name   = arguments.template_name  ?: "";
		var blueprint_name  = arguments.blueprint_name ?: "";
		var item            = arguments.item           ?: "";

		var label = [ item ];
		if( Len( template_name ) ){
			ArrayPrepend( label, translateResource( uri="preside-objects.email_layout_config_item:renderer.labels.template_prefix", data=[ template_name ] ) );
		} else if( Len( blueprint_name ) ){
			ArrayPrepend( label, translateResource( uri="preside-objects.email_layout_config_item:renderer.labels.blueprint_prefix", data=[ blueprint_name ] ) );
		}

		return ArrayToList( label, " - " );
	}
}