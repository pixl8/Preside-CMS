<cfoutput>
	<form id="#prc.formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#prc.formAction#">
			#renderForm(
				  formName          = prc.formName
				, context           = "admin"
				, formId            = prc.formId
				, validationResult  = rc.validationResult ?: ""
			)#
		<div class="form-actions row">
			<div class="col-md-offset-2">
				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:robotsTxt.save.button" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>