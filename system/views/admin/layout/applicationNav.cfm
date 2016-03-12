<cfscript>
	selected     = args.selectedApplication ?: "cms";
	applications = args.applications ?: [];
</cfscript>

<cfoutput>
	<div class="navbar-header pull-left btn-group">
		<ul class="nav ace-nav">
			<li class="application-menu">
				<cfif applications.len() gt 1>
					<a data-toggle="dropdown" href="##" class="dropdown-toggle">
				</cfif>
				<span class="navbar-brand">
					#translateResource( uri="applications:#selected#.title" )#
				</span>

				<cfif applications.len() gt 1>
						<i class="fa fa-caret-down application-menu-toggle"></i>
					</a>
				</cfif>

				<cfif applications.len() gt 1>


					<ul class="dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
						<cfloop array="#applications#" index="i" item="app">
							#renderViewlet( event="admin.layout.applicationDropdownItem", args={ app=app } )#
						</cfloop>
					</ul>
				</cfif>
			</li>
		</ul>
	</div>
</cfoutput>