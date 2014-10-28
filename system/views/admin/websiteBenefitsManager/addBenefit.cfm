<cfscript>
	prc.pageIcon  = "unlock";
	prc.pageTitle = translateResource( "cms:websitebenefitsmanager.addBenefit.page.title" );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = "website_benefit"
		, addRecordAction       = event.buildAdminLink( linkTo='websitebenefitsmanager.addBenefitAction' )
		, allowAddAnotherSwitch = true
		, cancelAction          = event.buildAdminLink( linkTo='websitebenefitsmanager' )
	} )#
</cfoutput>