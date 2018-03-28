<cfscript>
	param name="prc.category"  type="ConfigCategory";
	param name="prc.savedData" type="struct";
	param name="prc.formName"  type="string";

	formId     = "edit-system-config-" & ( rc.id ?: "" );
	sites      = prc.sites ?: QueryNew('');
	categoryId = Trim( rc.id   ?: "" );
	site       = Trim( rc.site ?: "" );
	version    = Trim( rc.version ?: "" );
	canSaveDraft = false;

	isSiteConfig = sites.recordCount > 1 && site.len();
</cfscript>

<cfoutput>
	#renderViewlet( event='admin.datamanager.groupVersionNavigator', args={
		  object           = "system_config"
		, id               = categoryId
		, version          = version
		, isDraft          = IsTrue( page._version_is_draft ?: "" )
		, baseUrl          = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#&version=" )
		, allVersionsUrl   = event.buildAdminLink( linkTo="sysconfig.configHistory", queryString="id=#categoryId#" )
		<!--- sysconfig.discardDraftsAction event will not be available, but that is not needed here as we don't support drafts for settings --->
		, discardDraftsUrl = ( canSaveDraft ? event.buildAdminlink( linkTo="sysconfig.discardDraftsAction", queryString="id=#categoryId#" ) : "" )
	} )#
	<cfif sites.recordcount gt 1>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<li<cfif site eq ""> class="active"</cfif>>
					<cfset link = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#" ) />
					<a href="#link#">
						<i class="fa fa-fw fa-cogs"></i>
						#translateResource( "cms:sysConfig.global.settings")#
					</a>
				</li>
				<cfloop query="sites">
					<li<cfif site eq sites.id> class="active"</cfif>>
						<cfset link = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#&site=#sites.id#" ) />
						<a href="#link#">
							<i class="fa fa-fw fa-globe"></i>
							#sites.name# (#sites.domain##sites.path#)
						</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
	</cfif>


	<form id="#formId#" method="post" action="#event.buildAdminLink( linkTo='sysConfig.saveCategoryAction' )#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" enctype="multipart/form-data">
		<input type="hidden" name="id"   value="#categoryId#">
		<input type="hidden" name="site" value="#site#">

		<cfif isSiteConfig>
			<p class="alert alert-info">
				<i class="fa fa-fw fa-info-circle"></i>
				#translateResource( uri="cms:sysConfig.site.config.info" )#
			</p>
		</cfif>

		#renderForm(
			  formName          = prc.formName
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.savedData
			, validationResult  = rc.validationResult ?: ""
			, fieldLayout       = isSiteConfig ? "formcontrols.layouts.fieldWithOverrideOption"    : NullValue()
			, fieldsetLayout    = isSiteConfig ? "formcontrols.layouts.fieldsetWithOverrideOption" : NullValue()
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sysConfig.save.button" )#
				</button>
			</div>
		</div>
	</form>

	<cfif sites.recordcount gt 1>
		</div>
	</cfif>
</cfoutput>