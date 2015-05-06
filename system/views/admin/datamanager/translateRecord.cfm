<cfscript>
	object              = rc.object ?: "";
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
	currentLanguage     = prc.language ?: {};
	currentLanguageId   = rc.language ?: "";
	id                  = rc.id ?: "";
	version             = rc.version ?: "";
	recordLabel         = prc.recordLabel;
	useVersioning       = prc.useVersioning ?: false;
	formName            = prc.formName ?: "";

	deleteRecordLink   = event.buildAdminLink( linkTo="datamanager.deleteTranslationAction", queryString="object=#object#&id=#id#&language=#currentLanguageId#" );
	deleteRecordPrompt = translateResource( uri="cms:datamanager.deleteTranslation.prompt", data=[ currentLanguage.name, objectTitleSingular, recordLabel ] )
	deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.btn" )

	canDelete        = prc.canDelete;
	translations     = prc.translations ?: [];
	translateUrlBase = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#id#&language=" );

	formId = "translate-record-form";
</cfscript>
<cfoutput>
	<div class="top-right-button-group">
		<cfif translations.len() gt 1>
			<button data-toggle="dropdown" class="btn btn-sm btn-info pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-globe"></i>&nbsp; #translateResource( uri="cms:datamanager.translate.record.btn" )#
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
		<cfif canDelete>
			<a class="pull-right inline confirmation-prompt" data-context-key="d" href="#deleteRecordLink#" title="#htmleditformat(deleteRecordPrompt)#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#deleteRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	<cfif useVersioning>
		#renderViewlet( event='admin.datamanager.translationVersionNavigator', args={ object=rc.object ?: "", id=rc.id ?: "", version=rc.version ?: "", language=currentLanguageId } )#
	</cfif>

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#event.buildAdminLink( linkTo='datamanager.translateRecordAction' )#">
		<input type="hidden" name="object"   value="#object#" />
		<input type="hidden" name="id"       value="#id#" />
		<input type="hidden" name="language" value="#currentLanguageId#" />
		<cfif useVersioning>
			<input type="hidden" name="version" value="#version#" />
		</cfif>

		#renderForm(
			  formName           = formName
			, context            = "admin"
			, formId             = formId
			, savedData          = prc.record ?: {}
			, validationResult   = rc.validationResult ?: ""
			, defaultI18nBaseUri = "preside-objects.#object#:"
		)#

		<div class="form-actions row">
			#renderFormControl(
				  type         = "yesNoSwitch"
				, context      = "admin"
				, name         = "_translation_active"
				, id           = "_translation_active"
				, label        = translateResource( uri="cms:datamanager.translation.active" )
				, savedData    = prc.record ?: {}
				, defaultValue = IsTrue( prc.record._translation_active ?: "" )
			)#

			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='datamanager.editRecord', queryString='object=#object#&id=#id#' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:datamanager.cancel.btn" )#
				</a>

				<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">

					<i class="fa fa-check bigger-110"></i>
					#translateResource( "cms:datamanager.savechanges.btn" )#
				</button>
			</div>
		</div>
	</form>
</cfoutput>