<cfparam name="args.isGitClone"     type="boolean" />
<cfparam name="args.currentVersion" type="string"  />

<cfoutput>
	<footer class="footer">
		<cfif args.isGitClone>
			#translateResource( uri='cms:cms.git.branch', data=[ args.currentVersion ] )#
		<cfelse>
			#translateResource( uri='cms:cms.version', data=[ args.currentVersion ] )#
		</cfif>
	</footer>
</cfoutput>