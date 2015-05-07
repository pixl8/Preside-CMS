<cfscript>
	formId            = "translate-page-form";
	pageId            = rc.id ?: "";
	currentLanguageId = rc.language ?: "";
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal translate-page-form" method="post" action="#event.buildAdminLink( linkTo='sitetree.translatePageAction' )#">
		<input type="hidden" name="id"       value="#pageId#" />
		<input type="hidden" name="language" value="#currentLanguageId#" />

		#renderForm(
			  formName          = prc.mainFormName ?: ""
			, mergeWithFormName = prc.mergeFormName ?: ""
			, context           = "admin"
			, formId            = formId
			, savedData         = prc.savedTranslation ?: {}
			, validationResult  = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			#renderFormControl(
				  type         = "yesNoSwitch"
				, context      = "admin"
				, name         = "_translation_active"
				, id           = "_translation_active"
				, label        = translateResource( uri="cms:datamanager.translation.active" )
				, savedData    = prc.savedTranslation ?: {}
				, defaultValue = IsTrue( prc.savedTranslation._translation_active ?: "" )
			)#

			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='sitetree.editPage', queryString='id=#pageId#' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">

					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:sitetree.savepage.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>