<cfscript>
	objectName          = "website_benefit";
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[  objectTitleSingular  ] );
	prioritizeBtn       = translateResource( uri="cms:websitebenefitsmanager.prioritize.btn" );

	prc.pageIcon     = "unlock";
	prc.pageTitle    = translateResource( "cms:websitebenefitsmanager.benefitspage.title");
	prc.pageSubTitle = translateResource( "cms:websitebenefitsmanager.benefitspage.subtitle");
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "websiteBenefitsManager.prioritize" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="websitebenefitsmanager.prioritize" )#" data-global-key="p">
				<button class="btn btn-default btn-sm">
					<i class="fa fa-sort-amount-asc"></i>
					#prioritizeBtn#
				</button>
			</a>
		</cfif>
		<cfif hasCmsPermission( "websiteBenefitsManager.add" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="websitebenefitsmanager.addBenefit" )#" data-global-key="a">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-plus"></i>
					#addRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName      = objectName
		, useMultiActions = true
		, multiActionUrl  = event.buildAdminLink( linkTo='websiteBenefitsManager.deleteBenefitAction' )
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=websiteBenefitsManager.getBenefitsForAjaxDataTables" )
		, gridFields      = [ "label", "priority", "description" ]
		, allowDataExport = true
		, dataExportUrl   = event.buildAdminLink( linkTo="websiteBenefitsManager.exportAction" )
	} )#
</cfoutput>