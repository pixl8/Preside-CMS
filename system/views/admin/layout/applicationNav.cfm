<cfscript>
	selected      = args.selectedApplication ?: "cms";
	applications  = getSetting( "adminApplications" );
	dropDownItems = "";

	if ( applications.len() > 1 ) {
		for( var app in applications ) {
			dropDownItems &= renderView( "/admin/layout/applications/#app#/dropdownItem" );
		}
	}
</cfscript>

<cfoutput>
	<div class="navbar-header pull-left btn-group">
		<ul class="nav ace-nav">
			<li class="application-menu">
				<a data-toggle="dropdown" href="##" class="dropdown-toggle">
					<span class="navbar-brand">
						#renderView( "/admin/layout/applications/#selected#/selected" )#
					</span>

					<cfif Len( Trim( dropDownItems ) )>
						<i class="fa fa-caret-down application-menu-toggle"></i>

						<ul class="dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
							#dropDownItems#
						</ul>
					</cfif>
				</a>
			</li>
		</ul>
	</div>
</cfoutput>