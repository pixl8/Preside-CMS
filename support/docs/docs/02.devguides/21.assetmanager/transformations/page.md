---
id: transformations
title: Image asset transformations
---

## Introduction

A derivative is defined with an array of configured **transformations** that the original asset binary will be passed through in order to create a new version.

A transformation is defined as a CFML structure, with the following keys:

* **method (required)**: Method that matches a method implemented in the [[api-assettransformer]] service object
* **args (optional)**: Structure of arguments passed to the transformation *method*.
* **inputfiletype (optional)**: Only apply this transformation to images of this type. e.g. "pdf".
* **outputfiletype (optional)**: Expected output filetype of the transformation

An example using all of the above arguments, is the admin thumbnail derivative that works for both PDFs and images:

```luceescript
settings.assetmanager.derivatives.adminthumbnail = {
      permissions     = "inherit"
    , inEditor        = false
    , transformations = [
          { method="pdfPreview" , args={ page=1 }, inputfiletype="pdf", outputfiletype="jpg" }
        , { method="shrinkToFit", args={ width=200, height=200 } }
      ]
};
```

## Available transformations

There are three transformation methods built in to Preside:

* shrinkToFit
* resize
* pdfPreview

### shrinkToFit

**shrinkToFit** will resize an image so it fits within the specified width and height, while maintaining the source image's aspect ratio.

The following settings can be passed to the method in the **args** struct:

* **width (required)**: Maximum width in pixels for the resulting image.
* **height (required)**: Maximum height in pixels for the resulting image.
* **quality (optional)**: The image quality to use when resizing the image. Available values are `highestQuality`, `highQuality`, `mediumQuality`, `highestPerformance`, `highPerformance` and `mediumPerformance`. Defaults to `highPerformance`.

### resize

**resize** will resize and crop an image if necesary, and is probably the more often used transformation.

The following settings can be passed to the method in the **args** struct:

* **width (optional)**: Width in pixels for the resulting image.
* **height (optional)**: Height in pixels for the resulting image.
* **quality (optional)**: The image quality to use when resizing the image. Available values are `highestQuality`, `highQuality`, `mediumQuality`, `highestPerformance`, `highPerformance` and `mediumPerformance`. Defaults to `highPerformance`.
* **maintainAspectRatio (optional)**: Whether or not the aspect ratio of the source image should be maintained when resizing. Defaults to `false`.
* **useCropHint (optional)**: **Introduced in 10.9.0**. Whether or not the image should be cropped according to the crop hint, if one is defined. Defaults to `false`.

Note that while **width** and **height** are both optional, *at least one of them* is required.

#### Resize with width *or* height

If only one dimension is specified, then the image will be resized so it matches that width or height. Setting **maintainAspectRatio** is irrelevant here, as it will always be true: the image is resized proportionally; the unspecified dimension is not constrained.

#### Resize with width *and* height

If both **width** and **height** are specified, but **maintainAspectRatio** is `false`, then the whole image will be resized to those dimensions. If the aspect ratio of the transformation does not match the aspect ratio of the source image, the image will be stretched either vertically or horizontally to fit the new aspect ratio.

If both **width** and **height** are specified, and **maintainAspectRatio** is `true`, then the image will be cropped to the largest area possible that matches the target aspect ratio. By default, this will be based around the centre point of the image. However, **as of 10.9.0**, the asset edit UI includes a **cropping** tab which allows you to set the **focal point** of the image. If this is set, then the cropping process will keep this focal point as close as possible to the centre of the resulting image.

Also **introduced in 10.9.0** are **crop hints**. In the same **cropping** tab of the asset edit UI, you can set an area of the image as a crop hint. If **useCropHint** is set to `true`, then the image will be pre-cropped to the smallest size that includes the whole of the crop hint *before* the resizing is applied.

#### Examples

The following examples show the different results from different **resize** arguments, based on this source image:

![Source image for resize examples](images/transformations/dragonfly.jpg)

---

```luceescript
{ method="resize", args={ width=300 } }
```

![Resized to 300 wide](images/transformations/dragonfly-300.jpg)

---

```luceescript
{ method="resize", args={ width=300, height=300 } }
```

![300x300, maintainAspectRatio=false](images/transformations/dragonfly-300x300-squeezed.jpg)

---

```luceescript
{ method="resize", args={ width=300, height=300, maintainAspectRatio=true } }
```

![300x300, maintainAspectRatio=true](images/transformations/dragonfly-300x300.jpg)

---

```luceescript
{ method="resize", args={ width=300, height=300, maintainAspectRatio=true } }
```

![300x300 with focal point](images/transformations/dragonfly-300x300-focal-point.jpg)

*Focal point set in the asset edit UI towards the left of the image*

---

```luceescript
{ method="resize", args={ width=300, height=300, maintainAspectRatio=true, useCropHint=true } }
```

![300x300 with crop hint](images/transformations/dragonfly-300x300-crop-hint.jpg)

*Crop hint set in the asset edit UI around the centre of the image*
