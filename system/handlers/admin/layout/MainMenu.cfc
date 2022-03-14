component {

	private struct function sitetree( event, rc, prc, args={} ) {
		return {
			  feature       = "sitetree"
			, permissionKey = "sitetree.navigate"
			, active        = ListLast( event.getCurrentHandler(), "." ) == "sitetree"
			, link          = event.buildAdminLink( linkTo="sitetree" )
			, gotoKey       = "s"
			, icon          = "fa-sitemap"
			, title         = translateResource( 'cms:sitetree' )
		};
	}

	private struct function assetmanager( event, rc, prc, args={} ) {
		return {
			  feature       = "assetManager"
			, permissionKey = "assetmanager.general.navigate"
			, active        = ListLast( event.getCurrentHandler(), "." ) == "assetmanager"
			, link          = event.buildAdminLink( linkTo="assetmanager" )
			, gotoKey       = "a"
			, icon          = "fa-picture-o"
			, title         = translateResource( 'cms:assetManager' )
		}
	}

	private struct function datamanager( event, rc, prc, args={} ) {
		return {
			  feature       = "datamanager"
			, permissionKey = hasCmsPermission( "datamanager.navigate" )
			, active        = ListLast( event.getCurrentHandler(), ".") eq "datamanager" && ( IsTrue( prc.objectInDatamanagerUi ?: "" ) || !Len( Trim( prc.objectName ) ) )
			, link          = event.buildAdminLink( linkTo="datamanager" )
			, gotoKey       = "d"
			, icon          = "fa-database"
			, title         = translateResource( 'cms:datamanager' )
		};
	}

	private struct function emailcenter( event, rc, prc, args={} ) {
		return {
			  feature      = "emailcenter"
			, active       = ReFindNoCase( "^admin\.emailcenter\.", event.getCurrentEvent() )
			, icon         = "fa-envelope"
			, title        = translateResource( 'cms:emailCenter.menu.title' )
			, subMenuItems = [
			      "emailCenterCustomTemplates"
			    , "emailCenterSystemTemplates"
			    , "emailCenterLayouts"
			    , "emailCenterBlueprints"
			    , "emailCenterSettings"
			    , "emailCenterLogs"
			    , "emailCenterQueue"
			  ]
		};
	}

	private struct function emailCenterCustomTemplates( event, rc, prc, args={} ) {
		return {
			  feature       = "customEmailTemplates"
			, permissionKey = "emailcenter.customTemplates.navigate"
			, link          = event.buildAdminLink( linkTo="emailcenter.customTemplates" )
			, title         = translateResource( "cms:emailcenter.customTemplates.menu.title" )
			, active        = ReFindNoCase( "^admin\.emailcenter\.customTemplates", event.getCurrentEvent() )
		};
	}

	private struct function emailCenterSystemTemplates( event, rc, prc, args={} ) {
		return {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.systemTemplates.navigate"
			, link          = event.buildAdminLink( linkTo="emailcenter.systemtemplates" )
			, title         = translateResource( "cms:emailcenter.systemtemplates.menu.title" )
			, active        = ReFindNoCase( "^admin\.emailcenter\.systemtemplates", event.getCurrentEvent() )
		};
	}

	private struct function emailCenterLayouts( event, rc, prc, args={} ) {
		return {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.layouts.navigate"
			, link          = event.buildAdminLink( linkTo="emailcenter.layouts" )
			, title         = translateResource( "cms:emailcenter.layouts.menu.title" )
			, active        = ReFindNoCase( "^admin\.emailcenter\.layouts", event.getCurrentEvent() )
		};
	}

	private struct function emailCenterBlueprints( event, rc, prc, args={} ) {
		return {
			  feature       = "customEmailTemplates"
			, permissionKey = "emailcenter.blueprints.navigate"
			, link          = event.buildAdminLink( linkTo="emailcenter.blueprints" )
			, title         = translateResource( "cms:emailcenter.blueprints.menu.title" )
			, active        = ReFindNoCase( "^admin\.emailcenter\.blueprints", event.getCurrentEvent() )
		};
	}

	private struct function emailCenterSettings( event, rc, prc, args={} ) {
		return {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.settings.navigate"
			, link          = event.buildAdminLink( linkTo="emailcenter.settings" )
			, title         = translateResource( "cms:emailcenter.settings.menu.title" )
			, active        = ReFindNoCase( "^admin\.emailcenter\.settings", event.getCurrentEvent() )
		};
	}

	private struct function emailCenterLogs( event, rc, prc, args={} ) {
		return {
			  feature       = "emailcenter"
			, permissionKey = "emailcenter.logs.view"
			, link         = event.buildAdminLink( linkTo="emailcenter.logs" )
			, title        = translateResource( "cms:emailcenter.logs.menu.title" )
			, active       = ReFindNoCase( "^admin\.emailcenter\.logs", event.getCurrentEvent() )
		};
	}

	private struct function emailCenterQueue( event, rc, prc, args={} ) {
		return {
			  feature       = "customEmailTemplates"
			, permissionKey = "emailcenter.queue.view"
			, link          = event.buildAdminLink( linkTo="emailcenter.queue" )
			, title         = translateResource( "cms:emailcenter.queue.menu.title" )
			, active        = ReFindNoCase( "^admin\.emailcenter\.queue", event.getCurrentEvent() )
		};
	}

	private struct function formbuilder( event, rc, prc, args={} ) {
		if ( !isFeatureEnabled( "formbuilder2" ) ) {
			return {
				  feature       = "formbuilder"
				, permissionKey = "formbuilder.navigate"
				, active        = ListLast( event.getCurrentHandler(), ".") eq "formbuilder"
				, link          = event.buildAdminLink( linkTo="formbuilder" )
				, icon          = "fa-check-square-o"
				, title         = translateResource( 'formbuilder:admin.menu.title' )
			};
		}

		return {
			  feature       = "formbuilder"
			, icon          = "fa-check-square-o"
			, title         = translateResource( 'formbuilder:admin.menu.title' )
			, subMenuItems = [ "formbuilderQuestions", "formbuilderForms" ]
		};
	}

	private struct function formbuilderQuestions( event, rc, prc, args={} ) {
		return {
			  feature       = "formbuilder2"
			, permissionKey = "formquestions.navigate"
			, link          = event.buildAdminLink( objectName="formbuilder_question" )
			, title         = translateResource( "formbuilder:questions.menu.title" )
			, active        = ( prc.objectName ?: "" ) == "formbuilder_question"
		};
	}

	private struct function formbuilderForms( event, rc, prc, args={} ) {
		return {
			  feature       = "formbuilder"
			, permissionKey = "formbuilder.navigate"
			, link          = event.buildAdminLink( linkTo="formbuilder" )
			, title         = translateResource( 'formbuilder:forms.menu.title' )
			, active        = ListLast( event.getCurrentHandler(), ".") eq "formbuilder"
			, gotoKey       = "f"
		};
	}

	private struct function websiteUserManager( event, rc, prc, args={} ) {
		if ( isFeatureEnabled( "websiteBenefits" ) ) {
			return {
				  feature      = "websiteUsers"
				, icon         = "fa-group"
				, title        = translateResource( 'cms:websiteUserManager' )
				, subMenuItems = [ "websiteUsers", "websiteBenefits" ]
			}
		}

		return {
			  permissionKey = "websiteUserManager.navigate"
			, link          = event.buildAdminLink( linkTo="websiteUserManager" )
			, title         = translateResource( "cms:websiteUserManager.users" )
			, active        = ReFindNoCase( "\.?websiteUserManager$", event.getCurrentHandler() )
			, icon          = "fa-group"
		};
	}

	private struct function websiteUsers( event, rc, prc, args={} ) {
		return {
			  feature       = "websiteUsers"
			, permissionKey = "websiteUserManager.navigate"
			, link          = event.buildAdminLink( linkTo="websiteUserManager" )
			, title         = translateResource( "cms:websiteUserManager.users" )
			, active        = ReFindNoCase( "\.?websiteUserManager$", event.getCurrentHandler() )
		};
	}

	private struct function websiteBenefits( event, rc, prc, args={} ) {
		return {
			  feature       = "websiteBenefits"
			, permissionKey = "websiteBenefitsManager.navigate"
			, link          = event.buildAdminLink( linkTo="websiteUserManager" )
			, title         = translateResource( "cms:websiteUserManager.users" )
			, active        = ReFindNoCase( "\.?websiteUserManager$", event.getCurrentHandler() )
		};
	}

}