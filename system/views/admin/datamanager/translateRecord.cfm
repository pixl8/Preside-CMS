<cfscript>
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
	currentLanguage     = prc.language ?: {};
	currentLanguageId   = rc.language ?: "";
	object              = rc.object ?: "";
	id                  = rc.id ?: "";
	recordLabel         = prc.recordLabel;
	useVersioning       = prc.useVersioning ?: false;

	deleteRecordLink   = event.buildAdminLink( linkTo="datamanager.deleteTranslationAction", queryString="object=#object#&id=#id#&language=#currentLanguageId#" );
	deleteRecordPrompt = translateResource( uri="cms:datamanager.deleteTranslation.prompt", data=[ currentLanguage.name, objectTitleSingular, recordLabel ] )
	deleteRecordTitle = translateResource( uri="cms:datamanager.deleteRecord.btn" )

	canDelete        = prc.canDelete;
	translations     = prc.translations ?: [];
	translateUrlBase = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#id#&language=" );
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
</cfoutput>