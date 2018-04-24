<cfscript>
	topRightButtons  = prc.topRightButtons  ?: "";
	editRecordForm   = prc.editRecordForm   ?: "";
	versionNavigator = prc.versionNavigator ?: "";
</cfscript>

<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#versionNavigator#

	#editRecordForm#
</cfoutput>

<!--- <cfscript>
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
	translateUrlBase = event.buildAdminLink( objectName=object, recordId=id, operation="translateRecord", args={ language="{language}" } );
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
						<a href="#translateUrlBase.replace( '{language}', language.id )#">
							<i class="fa fa-fw fa-pencil"></i>&nbsp; #language.name# (#translateResource( 'cms:multilingal.status.#language.status#' )#)
						</a>
					</li>
				</cfloop>
			</ul>
		</cfif>
	</div>
</cfoutput> --->