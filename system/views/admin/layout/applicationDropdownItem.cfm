<cfscript>
	link        = args.link        ?: "";
	iconClass   = args.iconClass   ?: "";
	title       = args.title       ?: "";
	description = args.description ?: "";
</cfscript>

<cfoutput>
	<li class="application-list-item">
		<a href="#link#" class="application-link">
			<div class="application-listing">
				<h4 class="application-title">
					<i class="fa fa-fw #iconClass#"></i>&nbsp;
					#title#
				</h4>
				<cfif Len( Trim( description ) )>
					<span class="application-description">
						#description#
					</span>
				</cfif>
			</div>
		</a>
	</li>
</cfoutput>