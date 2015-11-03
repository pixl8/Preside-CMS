<cfparam name="args.source_url"       default=""      />
<cfparam name="args.async"            default="no"    />
<cfparam name="args.defer"  	      default="no"    />
<cfparam name="args.internal_script"  default=""      />

<cfoutput>
	<cfif !IsEmpty( args.source_url )>

		<cfif IsTrue( args.async )>
			<cfset method = "async" />
		<cfelseif IsTrue( args.defer )>
			<cfset method = "defer" />
		<cfelse>
			<cfset method = "" />
		</cfif>

		<script type="text/javascript" src="#args.source_url#" #method#></script>
	</cfif>

	<cfif !IsEmpty( args.internal_script )>
		#args.internal_script#
	</cfif>

</cfoutput>