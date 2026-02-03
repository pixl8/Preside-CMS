component {
	private array function _selectFields( event, rc, prc ) {
		return [
			  "email_template.name                     as template_name"
			, "email_blueprint.name                    as blueprint_name"
			, "email_layout_config_item.layout         as layout"
			, "email_layout_config_item.custom_layout  as custom_layout"
			, "item"
		];
	}

	private string function _orderBy( event, rc, prc ) {
		return "layout, email_template, email_blueprint, custom_layout, item"
	}

	private string function _renderLabel( event, rc, prc ) {
		var layout          = arguments.layout  ?: "";
		var template_name   = arguments.template_name  ?: "";
		var blueprint_name  = arguments.blueprint_name ?: "";
		var custom_layout   = arguments.custom_layout  ?: "";
		var item            = arguments.item           ?: "";

		var label = [ item ];
		if( Len( template_name ) ){
			ArrayPrepend( label, translateResource( uri="preside-objects.email_layout_config_item:renderer.labels.template_prefix", data=[ template_name ] ) )
		} else if( Len( blueprint_name ) ){
			ArrayPrepend( label, translateResource( uri="preside-objects.email_layout_config_item:renderer.labels.blueprint_prefix", data=[ blueprint_name ] ) );
		} else if( Len( custom_layout ) ){
			ArrayPrepend( label, translateResource( uri="preside-objects.email_layout_config_item:renderer.labels.custom_layout_prefix", data=[ custom_layout ] ) );
		} else {
			var layoutLabel = translateResource( "email.layout.#layout#:title" );
			ArrayPrepend( label, translateResource( uri="preside-objects.email_layout_config_item:renderer.labels.layout_prefix", data=[ layoutLabel ] ) );
		}

		return ArrayToList( label, " - " );
	}
}