<cfscript>
	if ( isFeatureEnabled( "formbuilder" ) ) {

		if ( isFeatureEnabled( "formbuilder2" ) ) {

			subMenuItems = [];
			anyActive = false;

			if ( hasCmsPermission( "formquestions.navigate" ) ) {
				subMenuItems.append( {
					  link  = event.buildAdminLink( objectName="formbuilder_question" )
					, title = translateResource( "formbuilder:questions.menu.title" )
					, active = ( prc.objectName ?: "" ) == "formbuilder_question"
				} );
				anyActive = anyActive || ArrayLast( subMenuItems ).active;
			}

			if ( hasCmsPermission( "formbuilder.navigate" ) ) {
				subMenuItems.append( {
					  link  = event.buildAdminLink( linkTo="formbuilder" )
					, title = translateResource( 'formbuilder:forms.menu.title' )
					, active = ListLast( event.getCurrentHandler(), ".") eq "formbuilder"
					, gotoKey = "f"
				} );
				anyActive = anyActive || ArrayLast( subMenuItems ).active;
			}

			if ( ArrayLen( subMenuItems ) ) {
				WriteOutput( renderView(
					  view = "/admin/layout/sidebar/_menuItem"
					, args = {
						  active       = anyActive
						, icon         = "fa-check-square-o"
						, title        = translateResource( 'formbuilder:admin.menu.title' )
						, subMenuItems = subMenuItems
					  }
				) );
			}

		} else if ( hasCmsPermission( "formbuilder.navigate" ) ) {
			writeOutput( renderView(
				  view = "/admin/layout/sidebar/_menuItem"
				, args = {
					  active  = ListLast( event.getCurrentHandler(), ".") eq "formbuilder"
					, link    = event.buildAdminLink( linkTo="formbuilder" )
					, icon    = "fa-check-square-o"
					, title   = translateResource( 'formbuilder:admin.menu.title' )
				  }
			) );
		}
	}
</cfscript>