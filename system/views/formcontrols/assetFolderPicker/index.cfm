<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	folders      = args.folders      ?: QueryNew('id,label,depth');
	root         = args.rootFolderId ?: "";

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<select class="object-picker" data-placeholder="#placeholder#" name="#inputName#" id="#inputId#" tabindex="#getNextTabIndex()#">
		<option>#HtmlEditFormat( translateResource( "cms:option.pleaseselect", "" ) )#</option>
		<option value="#root#"<cfif root eq value> selected="selected"</cfif>>#HtmlEditFormat( translateResource( "cms:assetmanager.folder.select.no.parent", "" ) )#</option>
		<cfloop query="folders">
			<option value="#folders.id#"<cfif folders.id eq value> selected="selected"</cfif>>#HtmlEditFormat( folders.label )#</option>
		</cfloop>
	</select>
</cfoutput>