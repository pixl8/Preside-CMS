<cfscript>
	param name="prc.category"  type="ConfigCategory";
	param name="prc.savedData" type="struct";
	param name="prc.formName"  type="string";

	formId         = "edit-system-config-" & ( rc.id ?: "" );
	categoryId     = Trim( rc.id             ?: "" );
	tenantId       = Trim( rc.tenantId       ?: "" );
	tenancyObject  = Trim( prc.tenancyObject ?: "" );
	tenancy        = Trim( prc.tenancy       ?: "" );
	tenancyRecords = prc.tenancyRecords ?: QueryNew( "" );

	isTenantConfig = tenancyRecords.recordCount > 1 && tenantId.len();

	tenantIcon = Len( tenancyObject ) ? translateResource( uri="preside-objects.#tenancyObject#:iconClass", defaultValue="fa-cogs" ) : "";
</cfscript>

<cfoutput>
	<cfif tenancyRecords.recordcount gt 1>
		<div class="tabbable tabs-left">
			<ul class="nav nav-tabs">
				<li<cfif tenantId == ""> class="active"</cfif>>
					<cfset link = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#" ) />
					<a href="#link#">
						<i class="fa fa-fw fa-cogs"></i>
						#translateResource( "cms:sysConfig.global.settings")#
					</a>
				</li>
				<cfloop query="tenancyRecords">
					<li<cfif tenantId == tenancyRecords.id> class="active"</cfif>>
						<cfset link = event.buildAdminLink( linkTo="sysconfig.category", queryString="id=#categoryId#&tenantId=#tenancyRecords.id#" ) />
						<a href="#link#">
							<i class="fa fa-fw #tenantIcon#"></i>
							#renderLabel( tenancyObject, tenancyRecords.id )#
						</a>
					</li>
				</cfloop>
			</ul>

			<div class="tab-content">
	</cfif>


	<form id="#formId#" method="post" action="#event.buildAdminLink( linkTo='sysConfig.saveCategoryAction' )#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" enctype="multipart/form-data">
		<input type="hidden" name="id"   value="#categoryId#">
		<input type="hidden" name="tenantId" value="#tenantId#">

		<cfif isTenantConfig>
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
			, fieldLayout       = isTenantConfig ? "formcontrols.layouts.fieldWithOverrideOption"    : NullValue()
			, fieldsetLayout    = isTenantConfig ? "formcontrols.layouts.fieldsetWithOverrideOption" : NullValue()
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

	<cfif tenancyRecords.recordcount gt 1>
		</div>
	</cfif>
</cfoutput>