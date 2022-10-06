component {

	private string function renderInput( event, rc, prc, args={} ) {
		event
			.include( "/css/frontend/formbuilder/accordion/" )
			.include( "/js/frontend/formbuilder/accordion/" )
		;

		return renderView( view="/formbuilder/item-types/accordion/renderInput", args=args );
	}

}