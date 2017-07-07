<cfparam name="args.url"    default=""           />
<cfparam name="args.width"  default="560"        />
<cfparam name="args.height" default="315"        />
<cfparam name="args.border"                      />
<cfparam name="args.full_screen" default="false" />

<cfif IsTrue(args.border)>
	<cfset border = 1 />
<cfelse>
	<cfset border = 0 />
</cfif>

<cfoutput>
	<iframe width="#args.width#" height="#args.height#" src="#args.url#" frameborder="#border#" <cfif isTrue( args.full_screen )>allowFullScreen="true" webkitallowfullscreen="true" mozallowfullscreen="true"</cfif> ></iframe>
</cfoutput>