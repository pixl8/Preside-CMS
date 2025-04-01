<cfscript>
    assetBinary = args.assetBinary ?: "";
</cfscript>

<cfoutput>
    <cfif !isEmpty( assetBinary ) >
        #decodeForHTML( assetBinary )#
    </cfif>
</cfoutput>