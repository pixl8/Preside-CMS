<!---@feature presideForms and customFields--->
<cfscript>
	nodeId           = args.id               ?: "";
	label            = args.label            ?: "";
	nodeType         = args.type             ?: "property";
	path             = args.path             ?: "";
	propertyName     = args.property         ?: "";
	relationshipPath = args.relationshipPath ?: "";
	hasChildren      = IsTrue( args.hasChildren ?: false );
</cfscript>

<cfoutput>
	<cfif hasChildren>
		<div class="tree-folder"
			 data-node-id="#EncodeForHtmlAttribute( nodeId )#"
			 data-type="#EncodeForHtmlAttribute( nodeType )#"
			 data-path="#EncodeForHtmlAttribute( path )#"
			 data-property="#EncodeForHtmlAttribute( propertyName )#"
			 data-relationship-path="#EncodeForHtmlAttribute( relationshipPath )#"
			 data-has-children="true"
		>
			<div class="tree-node tree-folder-header" tabindex="0">
				<i class="fa fa-fw fa-caret-right tree-node-toggler"></i>
				<div class="tree-folder-name node-name">
					<span class="node-label">#HtmlEditFormat( label )#</span>
				</div>
			</div>
			<div class="tree-folder-content"></div>
		</div>
	<cfelse>
		<div class="tree-node tree-item"
			 data-node-id="#EncodeForHtmlAttribute( nodeId )#"
			 data-type="#EncodeForHtmlAttribute( nodeType )#"
			 data-path="#EncodeForHtmlAttribute( path )#"
			 data-property="#EncodeForHtmlAttribute( propertyName )#"
			 data-relationship-path="#EncodeForHtmlAttribute( relationshipPath )#"
			 data-has-children="false"
			 tabindex="0"
		>
			<i class="fa fa-fw fa-caret-right related-data-tree-spacer"></i>
			<div class="tree-item-name node-name">
				<span class="node-label">#HtmlEditFormat( label )#</span>
			</div>
		</div>
	</cfif>
</cfoutput>
