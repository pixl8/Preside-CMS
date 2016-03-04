/**
 * Viewlets for form layouts within the form builder
 *
 */
component {

	public void function preHandler( event, rc, prc ) {
	}

	private string function default( event, rc, prc, args={} ) {
		return renderView( view="/formbuilder/layouts/form/default", args=args );
	}

}