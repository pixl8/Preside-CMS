component output=false {

	public string function default( event, rc, prc, args={} ){
		var data = args.data ?: "";
		var adminUserDetails = event.getAdminUserDetails();
		var dateFormatMask   = translateResource( uri="cms:dateFormat");
		
		if ( IsStruct(adminUserDetails) ) {
			if ( StructKeyExists(adminUserDetails, "user_admin_date_format") && Len(adminUserDetails.user_admin_date_format) ) {
				dateFormatMask = adminUserDetails.user_admin_date_format;
			}
		}

		if ( LSisDate( data ) ) {
			return LSdateFormat( LSparseDateTime( data ), dateFormatMask );
		}

		return data;
	}

}