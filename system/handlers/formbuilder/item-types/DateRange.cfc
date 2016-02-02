component {

	private string function renderInput( event, rc, prc, args={} ) {

		var name = args.name   ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = name&"_from"
			, toDate   			 = name&"_to"
			, type               = "DateRangepicker"
			, context            = "formbuilder"
			, fromDateID         = args.id ?: fromDate
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
		);
	}

	private any function getItemDataFromRequest( event, rc, prc, args={} ) {
	    var inputName = args.inputName ?: "";
	    return "Form - " &rc[ inputName & "_from" ]&" , To - " & rc[ inputName & "_to"   ];
	}
}