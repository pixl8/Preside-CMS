<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	roles        = args.roles        ?: ArrayNew(1);

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<cfloop array="#roles#" index="role">
		<div class="checkbox role-picker-checkbox">
			<label>
				<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#role#" type="checkbox"  value="#HtmlEditFormat( role )#"<cfif ListFindNoCase( value, role )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="role-title bigger">
						#translateResource( uri="roles:#role#.title" )#
					</span><br />
					<span class="role-desc">
						#translateResource( uri="roles:#role#.description" )#
					</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>