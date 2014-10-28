<cfscript>
	prc.pageIcon  = "unlock";
	prc.pageTitle = translateResource( uri="cms:websitebenefitsManager.editBenefit.page.title", data=[ prc.record.label ?: "" ] );
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "website_benefit"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='websiteBenefitsManager.editBenefitAction' )
		, cancelAction     = event.buildAdminLink( linkTo='websiteBenefitsManager' )
	} )#
</cfoutput>