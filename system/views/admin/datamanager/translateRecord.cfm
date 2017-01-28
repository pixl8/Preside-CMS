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

	deleteRecordLink    = event.buildAdminLink( linkTo="datamanager.deleteTranslationAction", queryString="object=#object#&id=#id#&language=#currentLanguageId#" );
	deleteRecordPrompt  = translateResource( uri="cms:datamanager.deleteTranslation.prompt", data=[ currentLanguage.name, objectTitleSingular, recordLabel ] );
	deleteRecordTitle   = translateResource( uri="cms:datamanager.deleteRecord.btn" );

	canDelete           = prc.canDelete;
	translations        = prc.translations     ?: [];
	translateUrlBase    = prc.translateUrlBase ?: event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#id#&language=" );
	cancelAction        = prc.cancelAction     ?: event.buildAdminLink( linkTo="datamanager.editRecord", querystring='object=#object#&id=#id#' );
	formAction          = prc.formAction       ?: event.buildAdminLink( linkTo='datamanager.translateRecordAction');
	formId              = "translate-record-form";

	draftsEnabled = IsTrue( prc.draftsEnabled ?: "" )
	canSaveDraft  = IsTrue( prc.canSaveDraft  ?: "" )
	canPublish    = IsTrue( prc.canPublish    ?: "" )


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

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal edit-object-form" method="post" action="#formAction#">
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
		)#

		<div class="col-md-offset-2">
			<a href="#cancelAction#" class="btn btn-default" data-global-key="c">
				<i class="fa fa-reply bigger-110"></i>
				#translateResource( "cms:datamanager.cancel.btn" )#
			</a>

			<cfif draftsEnabled>
				<cfif canSaveDraft>
					<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:datamanager.translate.record.draft.btn", data=[ LCase( objectTitleSingular ) ] )#
					</button>
				</cfif>
				<cfif canPublish>
					<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
						<i class="fa fa-globe bigger-110"></i> #translateResource( uri="cms:datamanager.translate.record.publish.btn", data=[ LCase( objectTitleSingular ) ] )#
					</button>
				</cfif>
			<cfelse>
				<button type="submit" name="_saveAction" value="add" class="btn btn-info" tabindex="#getNextTabIndex()#">
					<i class="fa fa-save bigger-110"></i> #translateResource( uri="cms:datamanager.translate.record.btn", data=[ LCase( objectTitleSingular ) ] )#
				</button>
			</cfif>
		</div>
	</form>
</cfoutput>