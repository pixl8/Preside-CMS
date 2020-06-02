<cfscript>
	objectName          = "url_redirect_rule";
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[  objectTitleSingular  ] );
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif hasCmsPermission( "urlRedirects.addRule" )>
			<a class="pull-right inline" href="#event.buildAdminLink( linkTo="urlRedirects.addRule" )#" data-global-key="a">
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
		, multiActionUrl  = event.buildAdminLink( linkTo='urlRedirects.deleteRuleAction' )
		, datasourceUrl   = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=urlRedirects.getRulesForAjaxDataTables" )
		, gridFields      = [ "label", "source_url_pattern", "redirect_to_link" ]
		, allowDataExport = true
		, dataExportUrl   = event.buildAdminLink( linkTo='urlRedirects.exportAction' )
	} )#
</cfoutput>