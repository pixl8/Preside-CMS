component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		event.include( assetId="/css/admin/frontend/" );
		event.include( assetId="/js/frontend/formbuilder/datePicker/" );
		return renderFormControl(
			  argumentCollection 			= arguments
			, name               			= controlName
			, type               			= "datepicker"
			, context            			= "formbuilder"
			, id                 			= args.id ?: controlName
			, layout             			= ""
			, required           			= IsTrue( args.mandatory ?: "" )
			, minDate            			= args.minDate ?: ""
			, maxDate                 		= args.maxDate ?: ""
			, greaterThanCurrentDate        = args.greaterThanCurrentDate 		 ?: ""
			, lessThanCurrentDate           = args.lessThanCurrentDate 		     ?: ""
			, greaterThanDateEnteredInField = args.greaterThanDateEnteredInField ?: ""
			, lessThanDateEnteredInField    = args.lessThanDateEnteredInField 	 ?: ""
		);
	}
}