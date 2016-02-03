component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName 			= args.name 			 ?: "";
		var dataManagerName 		= args.dataManager 		 ?: "";

		event.include( assetId="/js/frontend/formbuilder/select/" );

		formControl.name            = controlName;
		formControl.context         = "formbuilder";
		formControl.id              = args.id 				 ?: controlName;
		formControl.layout          = "";
		formControl.required        = IsTrue( args.mandatory ?: "" );
		formControl.multiple 		= args.multiple 		 ?: 0;
		formControl.values 			= args.values;
		formControl.class 			= "form-control";;
		formControl.labels			= args.Labels 			 ?: ""

		if(len(dataManagerName)) {
			formControl.object 		= dataManagerName;
			formControl.type        = "objectPicker";
			formControl.ajax 		= false;
		} else {
			formControl.type        = "select";
		}

		return renderFormControl(argumentCollection = formControl);
	}
}