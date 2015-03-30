<cfparam name="args.message" type="string" default="" />
<cfparam name="args.title"   type="string" default="We're sorry, this website is currently down for maintenance" />

<cfoutput><!DOCTYPE html>
<html>
	<head>
		<title>#args.title#</title>
		<meta charset="utf-8">
		<meta name="robots" content="noindex,nofollow" />
		<style type="text/css">
			body {
				background  : ##fff;
				font-family : arial;
				font-size   : 14px;
				padding     : 0;
				margin      : 0;
				color       : ##333;
			}

			##main {
				margin : 0 10%;
			}

			h1, h2 {
				margin      : 30px 0;
				font-weight : normal;
			}

			h1 span {
				color : ##808080;
			}

			h2 {
				color       : ##808080;
				font-size   : 1.4em;
			}

			h3{
				color:##434343;
				padding: 15px 0;
				border-bottom: 1px dotted ##d2d2d2;
			}

			ul li {
				margin:0;
			}

			p {
				font-size: 12px;
				margin: 20px 0;
			}
		</style>
	</head>
	<body>
		<div id="main">
			<h1><span>503</span> #args.title#</h1>

			#args.message#
		</div>
	</body>
</html></cfoutput>