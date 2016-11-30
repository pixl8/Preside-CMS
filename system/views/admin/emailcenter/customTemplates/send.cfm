<cfscript>
	templateId     = rc.id ?: "";
	cancelLink     = event.buildAdminLink( linkto="emailcenter.customTemplates.preview", queryString="id=" & templateId );
	recipientCount = Val( prc.recipientCount ?: 0 );
	filterObject   = prc.filterObject ?: "";
	gridFields     = prc.gridFields   ?: [];
</cfscript>

<cfoutput>
	<cfsavecontent variable="body">
		<cfif !recipientCount>
			<p class="alert alert-warning">
				<i class="fa fa-fw fa-exclamation-circle"></i>
				#translateResource( "cms:emailcenter.customTemplates.send.no.recipients.message" )#
			</p>
		<cfelse>
			<div class="alert alert-warning">
				<p>
					<i class="fa fa-fw fa-exclamation-circle"></i>
					#translateResource( uri="cms:emailcenter.customTemplates.send.message", data=[ NumberFormat( recipientCount ) ] )#
				</p>
				<br>
				<form action="#event.buildAdminLink( linkto='emailcenter.customTemplates.sendAction' )#" class="form-horizontal" method="post">
					<input type="hidden" name="id" value="#templateId#">
					<div class="row">
						<div class="col-md-12">
							<div class="pull-right">
								<a href="#cancelLink#" class="btn btn-default" data-global-key="c">
									<i class="fa fa-reply bigger-110"></i>
									#translateResource( "cms:cancel.btn" )#
								</a>

								<button type="submit" class="btn btn-danger" tabindex="#getNextTabIndex()#">
									<i class="fa fa-share bigger-110"></i>
									#translateResource( "cms:emailcenter.customtemplates.really.send.btn" )#
								</button>
							</div>
						</div>
					</div>
				</form>
			</div>

			<br>

			#renderView( view="/admin/datamanager/_objectDataTable", args={
				  objectName      = filterObject
				, useMultiActions = false
				, datasourceUrl   = event.buildAdminLink( linkTo="emailCenter.customTemplates.getRecipientListForAjaxDataTables", queryString="id=" & templateId )
				, gridFields      = gridFields
				, draftsEnabled   = false
				, allowSearch     = false
				, allowFilter     = false
			} )#
		</cfif>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="send" } )#
</cfoutput>