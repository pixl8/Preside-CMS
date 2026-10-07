<!---@feature admin and customObjects--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	categories   = args.categories   ?: [];
	listId       = "custom-object-categories-" & inputId;
	value        = event.getValue( name=inputName, defaultValue=defaultValue );

	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = EncodeForHtmlAttribute( value );
</cfscript>
<cfoutput>
	<input type="text" id="#inputId#" name="#inputName#" value="#value#" list="#listId#" class="#inputClass# form-control" tabindex="#getNextTabIndex()#" />
	<datalist id="#listId#">
		<cfloop array="#categories#" index="category">
			<option value="#EncodeForHtmlAttribute( category )#"></option>
		</cfloop>
	</datalist>
</cfoutput>
