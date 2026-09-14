<!---@feature admin--->
<cfscript>
	param name="args.addRecordAction"  type="string"  default=event.buildAdminLink( linkTo="datamanager.saveListingView" );
	param name="args.validationResult" type="any"     default=( rc.validationResult ?: "" );
	param name="args.savedData"        type="struct"  default=( prc.savedData ?: {} );
	param name="args.viewId"           type="string"  default=( rc.viewId ?: "" );
	param name="args.objectName"       type="string"  default=( rc.object ?: "" );
	param name="args.listingKey"       type="string"  default=( rc.listingKey ?: args.objectName );

	formId = "listing-view-save-form-" & CreateUUId();

	event.include( "/js/admin/specific/saveFilterForm/" )
	     .include( "/js/admin/specific/listingViewSaveForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal listing-view-save-form" method="post" action="#args.addRecordAction#">
		<input type="hidden" name="object"     value="#EncodeForHtmlAttribute( args.objectName )#" />
		<input type="hidden" name="listingKey" value="#EncodeForHtmlAttribute( args.listingKey )#" />
		<cfif Len( Trim( args.viewId ) )>
			<input type="hidden" name="viewId" value="#EncodeForHtmlAttribute( args.viewId )#" />
		</cfif>

		#renderForm(
			  formName         = "preside-objects.admin_datatable_saved_view.admin.save"
			, context          = "admin"
			, formId           = formId
			, savedData        = args.savedData
			, validationResult = args.validationResult
		)#
	</form>
</cfoutput>
