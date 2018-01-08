<cfscript>
	object              = rc.object ?: "";
	id                  = rc.id ?: "";
	recordLabel         = prc.recordLabel;
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	editRecordTitle     = translateResource( uri="cms:datamanager.editrecord.title", data=[  objectTitleSingular , recordLabel ] );
	useVersioning       = prc.useVersioning ?: false;

	prc.pageIcon  = "pencil";
	prc.pageTitle = editRecordTitle;

	canTranslate     = prc.canTranslate;
	translations     = prc.translations ?: [];
	translateUrlBase = event.buildAdminLink( linkTo="datamanager.translateRecord", queryString="object=#object#&id=#id#&language=" );
</cfscript>

<cfoutput>
	<div class="top-right-button-group">
		<cfif canTranslate && translations.len()>
			<button data-toggle="dropdown" class="btn btn-sm btn-info pull-right inline">
				<span class="fa fa-caret-down"></span>
				<i class="fa fa-fw fa-globe"></i>&nbsp; #translateResource( uri="cms:datamanager.translate.record.btn" )#
			</button>

			<ul class="dropdown-menu pull-right" role="menu" aria-labelledby="dLabel">
				<cfloop array="#translations#" index="i" item="language">
					<li>
						<a href="#translateUrlBase##language.id#">
							<i class="fa fa-fw fa-pencil"></i>&nbsp; #language.name# (#translateResource( 'cms:multilingal.status.#language.status#' )#)
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
	</div>

	<cfif useVersioning>
		#renderViewlet( event='admin.datamanager.versionNavigator', args={
			  object  = rc.object ?: ""
			, id      = rc.id ?: ""
			, version = rc.version ?: ""
			, isDraft = IsTrue( prc.record._version_is_draft ?: "" )
		} )#
	</cfif>



	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object        = ( rc.object  ?: "" )
		, id            = ( rc.id      ?: "" )
		, version       = ( rc.version ?: "" )
		, record        = ( prc.record ?: {} )
		, useVersioning = IsTrue( prc.useVersioning ?: "" )
		, draftsEnabled = IsTrue( prc.draftsEnabled ?: "" )
		, canSaveDraft  = IsTrue( prc.canSaveDraft  ?: "" )
		, canPublish    = IsTrue( prc.canPublish    ?: "" )
		, resultAction  = rc.resultAction  ?: ""
		, cancelAction  = prc.cancelAction ?: ""
	} )#
</cfoutput>