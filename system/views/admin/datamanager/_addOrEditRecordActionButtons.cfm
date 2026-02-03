<!---@feature admin--->
<cfscript>
	buttons = args.actionButtons ?: [];
</cfscript>

<cfoutput>
	<div class="col-md-offset-2">
		<cfloop array="#args.actionButtons#" item="button">
			<cfif button.type == "link">
				<a href="#button.href#" class="btn #( button.class ?: '' )#"<cfif Len( Trim( button.globalKey ?: '' ))> data-global-key="#button.globalKey#"</cfif> <cfif Len( Trim( button.id ?: '' ))> id="#button.id#"</cfif>>
					<cfif Len( Trim( button.iconClass ?: "" ) )>
						<i class="fa fa-fw #button.iconClass# bigger-110"></i>
					</cfif>

					#button.label#
				</a>
			<cfelse>
				<button type="submit" name="#( button.name ?: '' )#" value="#( button.value ?: '' )#" class="btn #( button.class ?: '' )#" tabindex="#getNextTabIndex()#">
					<cfif Len( Trim( button.iconClass ?: "" ) )>
						<i class="fa fa-fw #button.iconClass# bigger-110"></i>
					</cfif>
					#button.label#
				</button>
			</cfif>
		</cfloop>
	</div>
</cfoutput>