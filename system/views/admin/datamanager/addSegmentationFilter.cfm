<!---@feature admin--->
<cfscript>
	objectName   = prc.objectName   ?: "";
	submitAction = prc.submitAction ?: "";
	cancelAction = prc.cancelAction ?: "";
	formName     = prc.formName     ?: "";
</cfscript>
<cfoutput>
	<p class="alert alert-info">
		<i class="fa fa-fw fa-info-circle"></i>
		#translateResource( "cms:datamanager.managefilters.segmentation.filters.expo" )#
	</p>
	<form class="form form-horizontal" action="#submitAction#" id="add-segmentation-filter" method="post">
		<input type="hidden" name="object" value="#HtmlEditFormat( objectName )#" />

		#renderForm(
			  formName              = formName
			, context               = "admin"
			, formId                = "add-segmentation-filter"
			, validationResult      = ( rc.validationResult ?: "" )
			, additionalArgs        = { fields={ expressions={ object=objectName } } }
			, savedData             = { filter_object=objectName }
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-plus"></i>
					#translateResource( "cms:datamanager.managefilters.add.segmentation.filter.action.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>