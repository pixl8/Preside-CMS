<!---@feature admin and emailCenter--->
<cfscript>
	templateId = rc.template ?: ( rc.id ?: "" );
	showClicks = IsTrue( prc.showClicks ?: "" );
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<div class="clearfix">
			#renderViewlet(
				  event = "admin.emailcenter.templateStatsFilter"
				, args  = { templateId=templateId }
			)#
			#renderViewlet(
				  event = "admin.emailcenter.templateStatsSummary"
				, args  = { templateId=templateId }
			)#
		</div>

		<br>

		<cfif showClicks>
			<div class="row">
				<div class="col-md-8 col-lg-7">
		</cfif>

		#renderViewlet( event="admin.emailcenter.templateInteractionStatsChart", args={ templateId=templateId } )#

		<cfif showClicks>
				</div>
				<div class="col-md-4 col-lg-5">
					#renderViewlet( event="admin.emailcenter.templateClickStatsTable", args={ templateId=templateId } )#
				</div>
			</div>
		</cfif>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="stats" } )#
</cfoutput>