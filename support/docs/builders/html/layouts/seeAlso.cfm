<cfif ( args.links ?: [] ).len()>
	<cfoutput>
		<h2>See also</h2>
		<ul class="list-unstyled">
			<cfloop array="#args.links#" index="i" item="link">
				<li>#link#</li>
			</cfloop>
		</ul>
	</cfoutput>
</cfif>