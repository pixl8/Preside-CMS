<cfscript>
	formId                 = "translate-page-form";
	pageId                 = rc.id ?: "";
	currentLanguageId      = rc.language ?: "";
	version                = rc.version ?: "";
	translations           = prc.translations ?: [];
	translateUrlBase       = event.buildAdminLink( linkTo="sitetree.translatePage", queryString="id=#pageId#&language=" );
	pageTypeObjectName     = prc.pageTypeObjectName     ?: "page";
	pageIsMultilingual     = prc.pageIsMultilingual     ?: false;
	pageTypeIsMultilingual = prc.pageTypeIsMultilingual ?: false;

	canPublish   = IsTrue( prc.canPublish   ?: "" );
	canSaveDraft = IsTrue( prc.canSaveDraft ?: "" );
</cfscript>

<cfoutput>
	<cfif translations.len() gt 1>
		<div class="top-right-button-group">
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
		</div>
	</cfif>

	#renderViewlet( event='admin.datamanager.translationVersionNavigator', args={
		  object         = pageIsMultilingual ? "page" : pageTypeObjectName
		, id             = pageId
		, version        = version
		, language       = currentLanguageId
		, baseUrl        = event.buildAdminLink( linkTo="sitetree.translatePage", queryString="id=#pageId#&language=#currentLanguageId#&version=" )
		, allVersionsUrl = event.buildAdminLink( linkTo="sitetree.translationHistory", queryString="id=#pageId#&language=#currentLanguageId#" )
		, isDraft        = IsTrue( prc.savedTranslation._version_is_draft ?: "" )
	} )#

	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal translate-page-form" method="post" action="#event.buildAdminLink( linkTo='sitetree.translatePageAction' )#">
		<input type="hidden" name="id"       value="#pageId#" />
		<input type="hidden" name="language" value="#currentLanguageId#" />

		#renderForm(
			  formName                = prc.mainFormName ?: ""
			, mergeWithFormName       = prc.mergeFormName ?: ""
			, context                 = "admin"
			, formId                  = formId
			, savedData               = prc.savedTranslation ?: {}
			, validationResult        = rc.validationResult ?: ""
			, stripPermissionedFields = true
			, permissionContext       = "page"
			, permissionContextKeys   = ( prc.pagePermissionContext ?: [] )
		)#

		<div class="form-actions row">
			<div class="col-md-offset-2">
				<a href="#event.buildAdminLink( linkTo='sitetree.editPage', queryString='id=#pageId#' )#" class="btn btn-default" data-global-key="c">
					<i class="fa fa-reply bigger-110"></i>
					#translateResource( "cms:sitetree.cancel.btn" )#
				</a>

				<cfif canSaveDraft>
					<button type="submit" name="_saveAction" value="savedraft" class="btn btn-info" tabindex="#getNextTabIndex()#">
						<i class="fa fa-save bigger-110"></i> #translateResource( "cms:sitetree.savepage.draft.btn" )#
					</button>
				</cfif>
				<cfif canPublish>
					<button type="submit" name="_saveAction" value="publish" class="btn btn-warning" tabindex="#getNextTabIndex()#">
						<i class="fa fa-globe bigger-110"></i> #translateResource( "cms:sitetree.savepage.btn" )#
					</button>
				</cfif>
			</div>
		</div>
	</form>
</cfoutput>