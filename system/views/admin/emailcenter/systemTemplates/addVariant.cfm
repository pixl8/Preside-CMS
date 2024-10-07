<!---@feature admin and emailCenter--->
<cfscript>
	templateId         = rc.template              ?: "";
	formName           = prc.formName             ?: "";
	addVariantAction   = prc.addVariantAction     ?: "";
	cancelAction       = prc.cancelAction         ?: "";
	formId             = "add-system-email-variant";
	variantPlaceholder = prc.variantPlaceholder   ?: "";
</cfscript>

<cfsavecontent variable="body">
	<cfoutput>
		<div class="row">
			<div class="col-md-12">
				<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#addVariantAction#">
					<input type="hidden" name="template" value="#templateId#" />

					#renderForm(
						  formName          = formName
						, context           = "admin"
						, formId            = formId
						, validationResult  = rc.validationResult ?: ""
						, additionalArgs    = { fields={ name={ placeholder=variantPlaceholder } } }
					)#

					<div class="form-actions row">
						<div class="col-md-offset-2">
							<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
								<i class="fa fa-reply bigger-110"></i>
								#translateResource( "cms:datamanager.cancel.btn" )#
							</a>

							<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
								<i class="fa fa-plus bigger-110"></i>
								#translateResource( "cms:emailcenter.systemTemplates.variants.add.button" )#
							</button>
						</div>
					</div>
				</form>
			</div>

		</div>
	</cfoutput>
</cfsavecontent>

<cfoutput>
	#renderViewlet( event="admin.emailcenter.systemtemplates._templateTabs", args={ body=body, tab="variants" } )#
</cfoutput>