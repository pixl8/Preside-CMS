<cfparam name="args.body"    type="string" />
<cfparam name="args.subject" type="string" default="" />

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <cfif Len( Trim( args.subject ) )><title><cfoutput>#args.subject#</cfoutput></title></cfif>

        <style type="text/css">
            .ExternalClass {width:100%;}

            .ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div {
                line-height: 100%;
            }

            body {-webkit-text-size-adjust:none; -ms-text-size-adjust:none;}

            body {margin:0; padding:0;}

            table td {border-collapse:collapse;}

            p {margin:0; padding:0; margin-bottom:16px;}

            h1, h2, h3, h4, h5, h6 {
                color: black;
                line-height: 100%;
            }

            a, a:link {
                color:#2A5DB0;
                text-decoration: underline;
            }

            body, #body_style {
                background:#fff;
                min-height:1000px;
                color:#333;
                font-family:Arial, Helvetica, sans-serif;
                font-size:16px;
            }

            span.yshortcuts { color:#fff; background-color:none; border:none;}
            span.yshortcuts:hover,
            span.yshortcuts:active,
            span.yshortcuts:focus {color:#fff; background-color:none; border:none;}

            a:visited { color: #3c96e2; text-decoration: none}
            a:focus   { color: #3c96e2; text-decoration: underline}
            a:hover   { color: #3c96e2; text-decoration: underline}

            @media only screen and (max-device-width: 480px) {
                body[yahoo] #container1 {display:block !important}
                body[yahoo] p {font-size: 10px}
            }

            @media only screen and (min-device-width: 768px) and (max-device-width: 1024px)  {
                body[yahoo] #container1 {display:block !important}
                body[yahoo] p {font-size: 16px}
            }
        </style>
    </head>
    <body style="background:#fff; min-height:1000px; color:#333;font-family:Arial, Helvetica, sans-serif; font-size:16px" alink="#2A5DB0" link="#2A5DB0" bgcolor="#FFFFFF" text="#333333" yahoo="fix">
        <div id="body_style" style="padding:15px">
            <cfoutput>#args.body#</cfoutput>
        </div>
    </body>
</html>