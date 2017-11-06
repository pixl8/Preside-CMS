<cfscript>
	object              = rc.object ?: "";
	id                  = rc.id ?: "";
	language            = rc.language ?: "";
	version             = Val( rc.version ?: "" );
	recordLabel         = prc.recordLabel ?: "";
	objectTitleSingular = prc.objectName  ?: "";
	renderedRecord      = prc.renderedRecord ?: "";

	canEdit       = IsTrue( prc.canEdit       ?: "" );
	canDelete     = IsTrue( prc.canDelete     ?: "" );
	useVersioning = IsTrue( prc.useVersioning ?: "" );

	if ( canEdit ) {
		if ( language.len() ) {
			editRecordLink  = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#id#&language=#language#" );
		} else {
			editRecordLink  = event.buildAdminLink( linkTo="datamanager.editRecord", queryString="object=#object#&id=#id#" );
		}
		editRecordTitle = translateResource( uri="cms:datamanager.editRecord.btn" );
	}
	if ( canDelete ) {
		deleteRecordLink   = event.buildAdminLink( linkTo="datamanager.deleteRecordAction", queryString="object=#object#&id=#id#" );
		deleteRecordPrompt = translateResource( uri="cms:datamanager.deleteRecord.prompt", data=[ objectTitleSingular, recordLabel ] );
		deleteRecordTitle  = translateResource( uri="cms:datamanager.deleteRecord.btn" );
	}

	canTranslate     = prc.canTranslate;
	translations     = prc.translations ?: [];
	translateUrlBase = event.buildAdminLink( linkTo="datamanager.viewRecord", queryString="object=#object#&id=#id#&language=" );
</cfscript>


<cfoutput>
	<div class="top-right-button-group">
		<cfif canTranslate && translations.len()>
			<button data-toggle="dropdown" class="btn btn-sm btn-info pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-globe"></i>&nbsp; #translateResource( uri="cms:datamanager.translate.record.btn" )#
			</button>

			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<li>
					<a href="#translateUrlBase#">
						<i class="fa fa-fw fa-eye"></i>&nbsp; #translateResource( 'cms:datamanager.translate.default.language' )#
					</a>
				</li>

				<cfloop array="#translations#" index="i" item="language">
					<li>
						<a href="#translateUrlBase##language.id#">
							<i class="fa fa-fw fa-eye"></i>&nbsp; #language.name# (#translateResource( 'cms:multilingal.status.#language.status#' )#)
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
		<cfif canDelete>
			<a class="pull-right inline confirmation-prompt" href="#deleteRecordLink#" title="#HtmlEditFormat( deleteRecordPrompt )#">
				<button class="btn btn-danger btn-sm">
					<i class="fa fa-trash-o"></i>
					#deleteRecordTitle#
				</button>
			</a>
		</cfif>
		<cfif canEdit>
			<a class="pull-right inline" data-global-key="e" href="#editRecordLink#">
				<button class="btn btn-success btn-sm">
					<i class="fa fa-pencil"></i>
					#editRecordTitle#
				</button>
			</a>
		</cfif>
	</div>

	<cfif useVersioning>
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object  = object
			, id      = id
			, version = version
			, isDraft = IsTrue( prc.record._version_is_draft ?: "" )
			, baseUrl = event.buildAdminLink( linkTo='datamanager.viewRecord', queryString='object=#object#&id=#id#&version=' )
		} )#
	</cfif>

	#renderedRecord#
</cfoutput>