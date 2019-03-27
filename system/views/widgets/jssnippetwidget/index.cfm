<cfparam name="args.source_url"    default=""   />
<cfparam name="args.async"         default="no" />
<cfparam name="args.defer"         default="no" />
<cfparam name="args.inline_script" default=""   />
<cfparam name="args.integrity"     default=""   />
<cfparam name="args.crossorigin"   default=""   />

<cfoutput>
	<cfif !IsEmpty( args.source_url )>
		<cfif IsTrue( args.async )>
			<cfset method = " async" />
		<cfelseif IsTrue( args.defer )>
			<cfset method = " defer" />
		<cfelse>
			<cfset method = "" />
		</cfif>

		<script type="text/javascript" src="#args.source_url#"#method# <cfif !isEmpty( args.integrity )>integrity="#args.integrity#" </cfif> <cfif !isEmpty( args.crossorigin )>crossorigin="#args.crossorigin#" </cfif>></script>
	</cfif>

	<cfif !IsEmpty( args.inline_script )>
		<script type="text/javascript">
			#args.inline_script#
		</script>
	</cfif>
</cfoutput>