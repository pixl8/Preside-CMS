<cfparam name="args.body"           default="">
<cfparam name="args.signature_text" default="">

<cfoutput>#args.body#<cfif Len( Trim( args.signature_text ) )>

#args.signature_text#</cfif></cfoutput>