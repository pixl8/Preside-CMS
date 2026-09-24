<!---@feature presideForms and customFields--->
<cfscript>
	inputName          = args.name               ?: "";
	inputId            = args.id                 ?: "";
	inputClass         = args.class              ?: "";
	targetObject       = args.targetObject       ?: "";
	nodes              = args.nodes              ?: [];
	relationshipValue  = args.relationshipValue  ?: "";
	propertyValue      = args.propertyValue      ?: "";
	propertyInputName  = args.propertyInputName  ?: "related_data_property";
	fetchUrl           = args.fetchUrl           ?: "";
	selectionLabel     = args.selectionLabel     ?: "";
	placeholder        = translateResource( uri="preside-objects.custom_field:field.related_data_relationship.placeholder" );

	if ( !Len( selectionLabel ) ) {
		selectionLabel = placeholder;
	}

	event.include( "/js/admin/specific/relatedDataTree/" )
	     .include( "/css/admin/specific/relatedDataTree/" );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<div class="related-data-tree"
		 data-fetch-url="#EncodeForHtmlAttribute( fetchUrl )#"
		 data-target-object="#EncodeForHtmlAttribute( targetObject )#"
		 data-property-input-name="#EncodeForHtmlAttribute( propertyInputName )#"
		 data-loading-text="#EncodeForHtmlAttribute( translateResource( uri='customFields:tree.loading' ) )#"
		 data-error-text="#EncodeForHtmlAttribute( translateResource( uri='customFields:tree.error' ) )#"
		 data-placeholder="#EncodeForHtmlAttribute( placeholder )#"
		 #htmlAttributes#
	>
		<input type="hidden" class="#inputClass#" id="#inputId#" name="#inputName#" value="#EncodeForHtmlAttribute( relationshipValue )#" />
		<p class="related-data-tree-summary">#HtmlEditFormat( selectionLabel )#</p>
		<div class="preside-tree-nav tree related-data-tree-nav">
			<cfloop array="#nodes#" item="node">
				#renderView( view="formcontrols/customFieldRelatedDataTree/_node", args=node )#
			</cfloop>
			<cfif !ArrayLen( nodes )>
				<p class="related-data-tree-empty">#translateResource( uri="customFields:tree.empty" )#</p>
			</cfif>
		</div>
	</div>
</cfoutput>
