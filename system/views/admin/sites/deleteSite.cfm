<!---@feature admin and sites--->
<cfscript>
	siteId           = rc.id                ?: "";
	site             = prc.record           ?: {};
	confirmationCode = prc.confirmationCode ?: "";
	cancelAction     = prc.cancelAction     ?: "";
	formAction       = prc.formAction       ?: "";
	formId           = "delete-site-form-#siteid#";
</cfscript>
<cfoutput>
	<p class="alert alert-warning">
		<i class="fa fa-fw fa-exclamation-triangle"></i>&nbsp;
		#translateResource( uri="cms:sites.deletesite.warning", data=[ "<strong>#site.name#</strong>" ] )#
	</p>

	<form id="#formId#" data-auto-focus-form="true" class="form-horizontal" method="post" action="#formAction#">
		<input type="hidden" name="id" value="#siteId#" />

		#renderForm(
			  formName         = "preside-objects.site.admin.delete"
			, context          = "admin"
			, formId           = formId
			, validationResult = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default">
					<i class="fa fa-fw fa-reply bigger-110"></i>

					#translateResource( "cms:cancel.btn" )#
				</a>
				<button type="submit" class="btn btn-danger" tabindex="#getNextTabIndex()#">
					<i class="fa fa-fw fa-trash bigger-110"></i>
					#translateResource( "cms:sites.deletesite.btn" )#
				</button>
			</div>
		</div>
	</form>

</cfoutput>