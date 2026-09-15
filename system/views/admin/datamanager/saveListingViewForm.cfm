<!---@feature admin--->
<cfscript>
	param name="args.addRecordAction"     type="string"  default=event.buildAdminLink( linkTo="datamanager.saveListingView" );
	param name="args.validationResult"    type="any"     default=( rc.validationResult ?: "" );
	param name="args.savedData"           type="struct"  default=( prc.savedData ?: {} );
	param name="args.viewId"              type="string"  default=( rc.viewId ?: "" );
	param name="args.objectName"          type="string"  default=( rc.object ?: "" );
	param name="args.listingKey"          type="string"  default=( rc.listingKey ?: args.objectName );
	param name="args.listingContextKey"   type="string"  default=( rc.listingContextKey ?: "" );
	param name="args.listingContextLabel" type="string"  default=( rc.listingContextLabel ?: "" );
	param name="args.namedListingContext" type="boolean" default=IsTrue( rc.namedListingContext ?: false );

	formId = "listing-view-save-form-" & CreateUUId();

	event.include( "/js/admin/specific/saveFilterForm/" )
	     .include( "/js/admin/specific/listingViewSaveForm/" );
</cfscript>

<cfoutput>
	<form id="#formId#" class="form-horizontal listing-view-save-form" method="post" action="#args.addRecordAction#">
		<input type="hidden" name="object"              value="#EncodeForHtmlAttribute( args.objectName )#" />
		<input type="hidden" name="listingKey"          value="#EncodeForHtmlAttribute( args.listingKey )#" />
		<input type="hidden" name="listingContextKey"   value="#EncodeForHtmlAttribute( args.listingContextKey )#" />
		<input type="hidden" name="namedListingContext" value="#args.namedListingContext#" />
		<cfif Len( Trim( args.viewId ) )>
			<input type="hidden" name="viewId" value="#EncodeForHtmlAttribute( args.viewId )#" />
		</cfif>

		#renderForm(
			  formName         = "preside-objects.admin_datatable_saved_view.admin.save"
			, context          = "admin"
			, formId           = formId
			, savedData        = args.savedData
			, validationResult = args.validationResult
			, suppressFields   = Len( Trim( args.listingContextLabel ) ) ? [] : [ "context_scope" ]
			, additionalArgs   = { fields={ context_scope={ listingContextLabel=args.listingContextLabel } } }
		)#
	</form>
</cfoutput>
