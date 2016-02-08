<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	captchaKey   = args.captchaKey   ?: "";
</cfscript>

<script src='https://www.google.com/recaptcha/api.js'></script>

<cfoutput>
	<div class="g-recaptcha" data-sitekey="#captchaKey#"></div>
	<input type="hidden" title="Please verify that you are not a robot." class="hiddencode required" name="hiddencode" id="hiddencode">
</cfoutput>