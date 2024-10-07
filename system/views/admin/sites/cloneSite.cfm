<!---@feature admin and sites--->
<cfscript>
	siteId       = rc.id             ?: "";
	formName     = prc.cloneFormName ?: "";
	formAction   = prc.formAction    ?: "";
	cancelAction = prc.cancelAction  ?: "";
	formId       = "clone-site-#siteId#";
</cfscript>

<cfoutput>
	<p class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "cms:sites.clonesite.intro" )#
	</p>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal" method="post" action="#formAction#">
		<input type="hidden" name="id" value="#siteId#" />

		#renderForm(
			  formName                = formName
			, context                 = "admin"
			, formId                  = formId
			, savedData               = prc.record ?: {}
			, validationResult        = rc.validationResult ?: ""
			, stripPermissionedFields = true
			, permissionContext       = "site"
			, permissionContextKeys   = [ siteId ]
		)#


		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button type="submit" class="btn btn-info" tabindex="#getNextTabIndex()#">
					<i class="fa fa-clone bigger-110"></i> #translateResource( "cms:sites.clonesite.btn" )#
				</button>
			</div>
		</div>
	</form>

</cfoutput>