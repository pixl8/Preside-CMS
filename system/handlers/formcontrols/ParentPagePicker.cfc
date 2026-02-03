/**
 * @feature presideForms and siteTree
 */
component {

	public string function index( event, rc, prc, args={} ) {
		args.childPage = args.childPage ?: rc.id ?: "";

		return renderViewlet(
			  event = "formcontrols.siteTreePagePicker.index"
			, args  = args
		);
	}
}