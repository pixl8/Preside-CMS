<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	placeholder  = args.placeholder  ?: "";
	defaultValue = args.defaultValue ?: "";
	pageTypes    = args.pageTypes    ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<select class="object-picker" data-placeholder="#placeholder#" name="#inputName#" id="#inputId#" tabindex="#getNextTabIndex()#">
		<option>#translateResource( "cms:option.pleaseselect", "" )#</option>
		<cfloop array="#pageTypes#" index="pageType">
			<option value="#pageType.getId()#"<cfif value eq pageType.getId()> selected="selected"</cfif>>#translateResource( uri=pageType.getName(), defaultVaue=pageType.getId() )#</option>
		</cfloop>
	</select>
</cfoutput>