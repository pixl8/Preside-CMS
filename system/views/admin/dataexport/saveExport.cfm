<cfoutput>
	<form class="form-horizontal save-export-config-form" data-auto-focus-form="true" method="post" action="#event.buildAdminLink( objectName=rc.object, operation="saveExportAction" )#" id="save-export-config-form">
		#renderForm(
			  formName = "dataExport.saveExportConfiguration"
			, context  = "admin"
			, formId   = "save-export-config-form"
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<cfif !isEmpty( rc.object ?: "" )>
					<a href="#event.buildAdminLink( objectName=rc.object )#" class="btn btn-default" data-global-key="c">
						<i class="fa fa-reply bigger-110"></i>
						#translateResource( "cms:cancel.btn" )#
					</a>
				</cfif>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:savedexport.saveexport.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>