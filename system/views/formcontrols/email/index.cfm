<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	icon         = args.icon         ?: "";
	defaultValue = args.defaultValue ?: "";
	multiple     = isTrue( args.multiple ?: "" );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<label>
		<span class="block <cfif Len( Trim( icon ) )>input-icon input-icon-right</cfif>">
			<input type="email" class="#inputClass# span12" placeholder="#placeholder#" multiple="#multiple#" name="#inputName#" value="#HtmlEditFormat( value )#" tabindex="#getNextTabIndex()#" #htmlAttributes# />
			<cfif Len( Trim ( icon ) )>
				<i class="fa fa-#icon#"></i>
			</cfif>
		</span>
	</label>
</cfoutput>
