---
id: derivatives
title: Configuring Image Derivatives
---

This page will serve as your guide on configuring image derivatives on your application. To start with, please open the file /website/config/Config.cfc then copy the code below:


```luceescript
private struct function _getConfiguredAssetDerivatives() {
	var derivatives  = super._getConfiguredAssetDerivatives();

	derivatives.homebanner = {
		  permissions = "inherit"
		, inEditor    = true
		, transformations = [
			  { method="Resize", args={ width=1900, height=800, maintainaspectratio=true } }
		  ]
	};


	return derivatives;
}
```


### Derivatives Options

You can pass the following arguments to the derivatives:

<div class="table-responsive">
    <table class="table">
        <thead>
            <tr>
                <th>Name</th>
                <th>Description</th>
            </tr>
        </thead>
        <tbody>


            <tr>
                <td>`permissions`</td>
                <td>Please set the permission to inherit if you want the derivatives be used anywhere in the application, this is a required paramater. Default:'inherit'</td>
            </tr>

            <tr>
                <td>`inEditor`</td>
                <td>Please set the inEditor to true if you want the derivatives setting to become available on the editor. Default:'false'</td>
            </tr>

        </tbody>
    </table>
</div>

### i18n Settings

You can chanage the name/label of derivatives via i18n/derivatives.properties using this format: derivativeName.title = Desired Name


```luceescript

adminThumbnail.title=Admin thumbnail
icon.title=Icon thumbnail

```

>>> This feature was first introduced in PresideCMS v10.3.7. The details below do not apply for older versions of the software.