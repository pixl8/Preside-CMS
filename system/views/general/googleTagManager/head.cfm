<cfsavecontent  variable="googleTagManagerInfo">
    <cfoutput>
        <cfif len ( event.GETSITE().tagManagerID ) >
            dataLayer = [{'siteName': '#event.GETSITE().name#'}];
        </cfif>
    </cfoutput>
</cfsavecontent>

<!-- Global site tag (gtag.js) - Google Analytics -->

<script type="text/javascript" language="JavaScript">
    <cfoutput>
        var #toScript(event.GETSITE().tagManagerID, "tagManagerID")#;
        var #toScript(event.GETSITE().containerID, "containerID")#;
    </cfoutput>
</script>

<cfoutput>
    <script async src="https://www.googletagmanager.com/gtag/js?id=#event.GETSITE().tagManagerID#"></script>
</cfoutput>

<!--google tracking -->
<script>
    //Google Analytics
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', tagManagerID);

    //Google Tag Manager
    (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
    new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
    j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
    'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
    })(window,document,'script','dataLayer',containerID);<cfoutput>#trim(googleTagManagerInfo)#</cfoutput>
</script>
<!-- End Google Tag Manager -->