<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	strengths    = args.strengths    ?: [];

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<cfloop array="#strengths#" index="strength">
		<div class="radio role-picker-radio">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#strength.name#" type="radio" value="#strength.minValue#"<cfif ListFindNoCase( value, strength.minValue )> checked="checked"</cfif> tabindex="#getNextTabIndex()#" #htmlAttributes# />
				<span class="lbl">
					<span class="role-title bigger">
						#translateResource( uri="cms:password.strength.#strength.name#.title" )#
					</span><br />
					<span class="role-desc">
						#translateResource( uri="cms:password.strength.#strength.name#.description" )#
					</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>
