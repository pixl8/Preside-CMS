<cfscript>
    assetBinary = args.assetBinary ?: "";
</cfscript>

<cfoutput>
    <cfif !IsEmpty( assetBinary ) >
        #DecodeForHTML( assetBinary )#
    </cfif>
</cfoutput>