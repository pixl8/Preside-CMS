---
id: formcontrol-simpleColourPicker
title: "Form control: Simple colour picker"
---

The `simpleColourPicker` control allows users to pick a colour from a pre-defined palette, and can return it as an RGB or hex value.

The [[api-simplecolourpickerservice]] exposes methods for creating and registering palettes, and other helper methods for working with colour values.


### Arguments

<div class="table-responsive">
    <table class="table">
        <tbody>
            <tr>
                <th>palette (optional)</th>
                <td>
                    Name of the pre-defined palette to use. Built-in palettes are "web64" (default), "web216", and "material". You can register additional palettes using the [[simplecolourpickerservice-registerpalette]] method. If the palette you specify is not found, the default palette will be used.
                </td>
            </tr>
            <tr>
                <th>colours (optional)</th>
                <td>
                    Alternatively, you can define a list of colours directly in the form XML file. This should be a pipe-separated list of RGB (e.g. <code>100,150,200</code>) or hex (e.g. <code>cc601a</code> or <code>fff</code>) values - or even a mixture of the two.
                </td>
            </tr>
            <tr>
                <th>rowLength (optional)</th>
                <td>
                    The maximum number of colours displayed on each row of the colour picker. Default is 16.
                </td>
            </tr>
            <tr>
                <th>colourFormat (optional)</th>
                <td>
                    "hex" (default) or "rgb". The format in which you would like the selected colour value to be returned.
                </td>
            </tr>
            <tr>
                <th>rawValue (optional)</th>
                <td>
                    True or false (default). Indicates whether to return the colour as a raw value (e.g. <code>ffcc00</code> or <code>0,150,255</code>) or as a valid CSS value (e.g. <code>#ffcc00</code> or <code>rgb(0,150,255)</code>). You might want to set this to true if, for example, you will be using the selected RGB value as the basis for an rgba() value.
                </td>
            </tr>
            <tr>
                <th>showInput (optional)</th>
                <td>
                    True or false (default). Indicates whether you want the selected colour to be displayed in an input field below the colour swatch, or just show the swatch.
                </td>
            </tr>
        </tbody>
    </table>
</div>

### Examples

```xml
<field name="colour" control="simpleColourPicker" palette="material" showInput="true" colourFormat="rgb" />
```

![Screenshot of a simple colour picker](images/screenshots/simpleColourPicker1.png)


```xml
<field name="colour" control="simpleColourPicker" colours="000|333|666|999|ccc|fff" rowLength="3" />
```

![Screenshot of a simple colour picker](images/screenshots/simpleColourPicker2.png)
