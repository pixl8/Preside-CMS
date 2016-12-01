<cfscript>
	providerId   = rc.id ?: "";
	formId       = "email-provider-settings";
	formName     = prc.formName ?: "";
	formAction   = event.buildAdminLink( linkto="emailcenter.settings.saveProviderSettingsAction" );
	site         = rc.site ?: "";
	isSiteConfig = Len( Trim( site ) );
	savedData    = prc.savedData ?: {};
	sites        = prc.sites ?: QueryNew('');
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<cfif sites.recordcount gt 1>
			<div class="tabbable tabs-left">
				<ul class="nav nav-tabs">
					<li<cfif site eq ""> class="active"</cfif>>
						<cfset link = event.buildAdminLink( linkTo="emailcenter.settings.provider", queryString="id=#providerId#" ) />
						<a href="#link#">
							<i class="fa fa-fw fa-cogs"></i>
							#translateResource( "cms:sysConfig.global.settings")#
						</a>
					</li>
					<cfloop query="sites">
						<li<cfif site eq sites.id> class="active"</cfif>>
							<cfset link = event.buildAdminLink( linkTo="emailcenter.settings.provider", queryString="id=#providerId#&site=#sites.id#" ) />
							<a href="#link#">
								<i class="fa fa-fw fa-globe"></i>
								#sites.name# (#sites.domain##sites.path#)
							</a>
						</li>
					</cfloop>
				</ul>

				<div class="tab-content">
		</cfif>

		<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#formAction#">
			<input name="id" type="hidden" value="#providerId#">
			<cfif isSiteConfig>
				<input name="site" type="hidden" value="#site#">
			</cfif>

			#renderForm(
				  formName          = formName
				, context           = "admin"
				, formId            = formId
				, savedData         = savedData
				, validationResult  = rc.validationResult ?: ""
				, fieldLayout       = isSiteConfig ? "formcontrols.layouts.fieldWithOverrideOption"    : NullValue()
				, fieldsetLayout    = isSiteConfig ? "formcontrols.layouts.fieldsetWithOverrideOption" : NullValue()
			)#

			<div class="form-actions row">
				<div class="col-md-offset-2">
					<button type="submit" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:save.btn" )#
					</button>
				</div>
			</div>
		</form>

		<cfif sites.recordcount gt 1>
			</div>
		</cfif>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.settings._generalSettingsTabs", args={ body=body, tab=providerId } )#
</cfoutput>