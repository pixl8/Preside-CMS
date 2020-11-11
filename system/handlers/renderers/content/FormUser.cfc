component {
	property name="websiteUserDao"  inject="presidecms:object:website_user";
	property name="securityUserDao" inject="presidecms:object:security_user";

	private string function default( event, rc, prc, args={} ) {
		args.response = prc.response ?: QueryNew( "" );

		if( args.response.recordCount ) {
			args.userRecord = _getUserRecord(
				  websiteUser   = args.response.website_user    ?: ""
				, adminUser     = args.response.admin_user      ?: ""
				, isWebsiteUser = IsTrue( args.response.is_website_user ?: "" )
				, isAdminUser   = IsTrue( args.response.is_admin_user   ?: "" )
			);
		}

		return renderView( view="renderers/content/FormUser/default", args=args );
	}

	private string function adminDataTable( event, rc, prc, args={} ) {
		args.userRecord = _getUserRecord(
			  websiteUser   = args.record.website_user    ?: ""
			, adminUser     = args.record.admin_user      ?: ""
			, isWebsiteUser = IsTrue( args.record.is_website_user ?: "" )
			, isAdminUser   = IsTrue( args.record.is_admin_user   ?: "" )
		);

		return renderView( view="renderers/content/FormUser/adminDataTable", args=args );
	}

	private struct function _getUserRecord(
		  string  websiteUser
		, string  adminUser
		, boolean isWebsiteUser
		, boolean isAdminUser
	) {
		if( isWebsiteUser ) {
			var websiteUserRecord = websiteUserDao.selectData( id=websiteUser );

			if( websiteUserRecord.recordCount ) {
				return {
					  id     = websiteUserRecord.id
					, name   = websiteUserRecord.display_name
					, email  = websiteUserRecord.email_address
					, linkTo = "websiteUserManager.viewUser"
				};
			}
		} else if ( isAdminUser ) {
			var adminUserRecord = securityUserDao.selectData( id=adminUser );

			if( adminUserRecord.recordCount ) {
				return {
					  id     = adminUserRecord.id
					, name   = adminUserRecord.known_as
					, email  = adminUserRecord.email_address
					, linkTo = "userManager.viewUser"
				};
			}
		}

		return {};
	}

}