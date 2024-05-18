/**
 * @feature formBuilder
 */
component {

	private string function renderInput( event, rc, prc, args={} ) {
		event
			.include( "/css/frontend/formbuilder/section/" )
			.include( "/js/frontend/formbuilder/section/" )
		;

		return renderView( view="/formbuilder/item-types/section/renderInput", args=args );
	}

}