/**
 * Viewlets for form field layouts within the form builder
 *
 * @feature formBuilder
 */
component {

	public void function preHandler( event, rc, prc ) {
	}

	private string function default( event, rc, prc, args={} ) {
		return renderView( view="/formbuilder/layouts/formfield/default", args=args );
	}

}