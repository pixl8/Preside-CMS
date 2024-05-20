<!---@feature admin--->
<cfscript>
	objectName         = args.objectName         ?: ( prc.objectName ?: "" );
	batchCustomActions = args.batchCustomActions ?: [];

	buttonTitle = translateResource( uri="cms:datamanager.batchCustomAction.title" );
</cfscript>
<cfoutput>
	<div class="btn-group batch-action-menu">
		<button data-toggle="dropdown" class="btn btn-info">
			<span class="fa fa-caret-down"></span>
			<i class="fa fa-pencil"></i>
			#buttonTitle#
		</button>

		<ul class="dropdown-menu" role="menu" aria-labelledby="dLabel">
			<cfloop array="#batchCustomActions#" index="i" item="action">
				<cfif isSimpleValue( action )>
						#action#
					<cfelseif isStruct( action )>
						<li>
							<a href="##" class="action <cfif Len( Trim( action.prompt ?: "" ) )> confirmation-prompt</cfif>"
							   name="#( action.name ?: '' )#"
							   disabled="disabled"
							   <cfif Len( Trim( action.globalKey ?: "" ) )> data-global-key="#action.globalKey#"</cfif>
							   <cfif Len( Trim( action.prompt ?: "" ))> title="#action.prompt#"</cfif>
							   <cfif Len( Trim( action.match ?: "" ))> data-confirmation-match="#action.match#"</cfif>
							>
								<cfif Len( Trim( action.iconClass ?: "" ) )>
									<i class="fa fa-fw #action.iconClass#"></i>
								</cfif>
								#( action.label ?: "" )#
							</a>
						</li>
					<cfelse>
						<!--- LEAVE EMPTY --->
					</cfif>
			</cfloop>
		</ul>
	</div>
</cfoutput>