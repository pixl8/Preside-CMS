<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	defaultValue = args.defaultValue ?: "";
	permissions  = args.permissions  ?: ArrayNew(1)

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}
</cfscript>

<cfoutput>
	<cfloop array="#permissions#" index="permission">
		<div class="checkbox global-permission-checkbox">
			<label>
				<input class="ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#permission#" type="checkbox" class="ace" value="#permission#"<cfif ListFindNoCase( value, permission )> checked="checked"</cfif> tabindex="#getNextTabIndex()#">
				<span class="lbl">
					<span class="permssion-title bigger">
						#translateResource( uri="permissions:#permission#.title" )#
					</span><br />
					<span class="permission-desc">
						#translateResource( uri="permissions:#permission#.description" )#
					</span>
				</span>
			</label>
		</div>
	</cfloop>
</cfoutput>