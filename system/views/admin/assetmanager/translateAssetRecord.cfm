<cfscript>
	object              = rc.object        ?: "";
	currentLanguage     = prc.language     ?: {};
	currentLanguageId   = rc.language      ?: "";
	id                  = rc.id            ?: "";
	recordLabel         = prc.recordLabel  ?: "";
	formName            = prc.formName     ?: "";
	translations        = prc.translations ?: [];
	formId              = "assetTranslate-record-form";
	translateUrlBase    = event.buildAdminLink( linkTo="assetManager.translateAssetRecord", queryString="object=#object#&id=#id#&language=" );
</cfscript>
<cfoutput>
	<div class="top-right-button-group">
		<cfif translations.len() gt 1>
			<button data-toggle="dropdown" class="btn btn-sm btn-info pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-globe"></i>&nbsp; #translateResource( uri="cms:assetManager.translate.record.btn" )#
			</button>

			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<cfloop array="#translations#" index="i" item="language">
					<cfif language.id != currentLanguageId>
						<li>
							<a href="#translateUrlBase##language.id#">
								<i class="fa fa-fw fa-pencil"></i>&nbsp; #language.name# (#translateResource( 'cms:multilingal.status.#language.status#' )#)
							</a>
						</li>
					</cfif>
				</cfloop>
			</ul>
		</cfif>
	</div>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-assetTranslation-form" method="post" action="#event.buildAdminLink( linkTo='assetManager.translateAssetRecordAction' )#">
		<input type="hidden" name="object"   value="#object#" />
		<input type="hidden" name="id"       value="#id#" />
		<input type="hidden" name="language" value="#currentLanguageId#" />

		#renderForm(
			  formName           = formName
			, context            = "admin"
			, formId             = formId
			, savedData          = prc.record ?: {}
			, validationResult   = rc.validationResult ?: ""
		)#

		<div class="form-actions row">
			#renderFormControl(
				  type         = "yesNoSwitch"
				, context      = "admin"
				, name         = "_translation_active"
				, id           = "_translation_active"
				, label        = translateResource( uri="cms:assetManager.translation.active" )
				, savedData    = prc.record ?: {}
				, defaultValue = IsTrue( prc.record._translation_active ?: "" )
			)#

			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='assetManager.editAsset', querystring="asset=#id#" )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">

					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:save.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>