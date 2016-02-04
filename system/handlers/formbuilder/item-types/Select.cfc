component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName 						= args.name 			 ?: "";
		var dataManagerName 					= args.dataManager 		 ?: "";

		formControl.name            			= controlName;
		formControl.context         			= "formbuilder";
		formControl.id              			= args.id 				 ?: controlName;
		formControl.layout          			= "";
		formControl.required        			= IsTrue( args.mandatory ?: "" );
		formControl.multiple 					= args.multiple 		 ?: 0;
		formControl.class 						= "form-control";;
		formControl.removeObjectPickerClass 	= true;

		if( len( dataManagerName ) ) {
			formControl.object 					= dataManagerName;
			formControl.type        			= "objectPicker";
			formControl.ajax 					= false;
		} else {
			formControl.type        			= "select";
			formControl.values 					= replaceNoCase( args.values, chr( 10 ), ',', 'All' ); // chr ( 10 ) means newline
			formControl.labels					= replaceNoCase( args.Labels, chr( 10 ), ',', 'All' )		 ?: "";
		}

		return renderFormControl( argumentCollection = formControl );
	}
}