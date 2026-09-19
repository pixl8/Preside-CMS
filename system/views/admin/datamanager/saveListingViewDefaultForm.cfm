<!---@feature admin--->
<cfscript>
	param name="args.addRecordAction"     type="string"  default=event.buildAdminLink( linkTo="datamanager.saveListingViewDefault" );
	param name="args.validationResult"    type="any"     default=( rc.validationResult ?: "" );
	param name="args.savedData"           type="struct"  default=( prc.savedData ?: { scope="individual" } );
	param name="args.viewId"              type="string"  default=( rc.viewId ?: "" );
	param name="args.objectName"          type="string"  default=( rc.object ?: "" );
	param name="args.listingKey"          type="string"  default=( rc.listingKey ?: args.objectName );
	param name="args.listingContextKey"   type="string"  default=( rc.listingContextKey ?: "" );
	param name="args.namedListingContext" type="boolean" default=IsTrue( rc.namedListingContext ?: false );
	param name="args.canShare"            type="boolean" default=false;

	formId = "listing-view-default-form-" & CreateUUId();

	event.include( "/js/admin/specific/saveFilterForm/" )
	     .include( "/js/admin/specific/listingViewDefaultForm/" );
</cfscript>
<cfoutput>
	<form id="#formId#" class="form-horizontal listing-view-default-form" method="post" action="#args.addRecordAction#">
		<input type="hidden" name="object"              value="#EncodeForHtmlAttribute( args.objectName )#" />
		<input type="hidden" name="listingKey"          value="#EncodeForHtmlAttribute( args.listingKey )#" />
		<input type="hidden" name="listingContextKey"   value="#EncodeForHtmlAttribute( args.listingContextKey )#" />
		<input type="hidden" name="namedListingContext" value="#args.namedListingContext#" />
		<input type="hidden" name="viewId"              value="#EncodeForHtmlAttribute( args.viewId )#" />

		#renderForm(
			  formName         = "admin.datamanager.saveListingViewDefault"
			, context          = "admin"
			, formId           = formId
			, savedData        = args.savedData
			, validationResult = args.validationResult
			, additionalArgs   = { fields={ scope={ canShare=args.canShare } } }
		)#
	</form>
</cfoutput>
