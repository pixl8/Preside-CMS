component {

	private string function renderInput( event, rc, prc, args={} ) {

		var fromDate = args.name   ?: "";
		var toDate   = args.toDate ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = fromDate
			, toDate   			 = toDate
			, type               = "DateRangepicker"
			, context            = "formbuilder"
			, fromDateID         = args.id ?: fromDate
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}
}