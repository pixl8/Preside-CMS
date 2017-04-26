---
title: PresideCMS-flavoured Markdown
id: docs-markdown
---

The base markdown engine used is [pegdown](https://github.com/sirthias/pegdown). Please see both the [official markdown website](http://daringfireball.net/projects/markdown/) and the the [pegdown repository](https://github.com/sirthias/pegdown) for the supported syntax.

On top of this base layer, the PresideCMS Documentation system processes its own special syntaxes for syntax highlighting, cross referencing and notice boxes. It also processes YAML front matter to glean extra metadata about pages.

## Syntax highlighting

Syntax highlighted code blocks start and end with three backticks on their own line with an optional lexer after the first set of ticks. 

For example, a code block using a 'luceescript' lexer, would look like this:

<pre>
```luceescript
x = y;
WriteOutput( x );
```
</pre>

A code block without syntax higlighting would look like this:

<pre>
```
x = y;
WriteOutput( x );
```
</pre>

>>> We have implemented two lexers for Lucee, `lucee` and `luceescript`. The former is used for tag based code, the latter, script based. For a complete list of available lexers, see the [Pygments website](http://pygments.org/docs/lexers/).

## Cross referencing

Cross referencing between pages can be achieved using a double square bracket syntax surrounding the id of the page you wish to link to. For example:

```html
[[function-abs]]
```

When the link is rendered, the title of the page will be passed to the renderer. To provide a custom text for the link, use the following syntax:

```html
[[function-abs|Custom link text]]
```

## Notice boxes

Various "notice boxes" can be rendered by using a nested blockquote syntax. The nesting level dictates the type of notice rendered.

### Info boxes

Info boxes use three levels of blockquote indentation:

```html
>>> An example info box
```

>>> An example info box

### Warning boxes

Warning boxes use four levels of blockquote indentation:

```html
>>>> An example warning box
```

>>>> An example warning box

### Important boxes

Important boxes use five levels of blockquote indentation:

```html
>>>>> An example 'important' box
```

>>>>> An example 'important' box

### Tip boxes

Tip boxes use six levels of blockquote indentation:

```html
>>>>>> An example tip box
```

>>>>>> An example tip box

## YAML Front Matter

YAML Front Matter is used to add metadata to pages that can then be used by the build system. The syntax takes the form of three dashes `---` at the very beginning of a markdown document, followed by a YAML block, followed by three dashes on their own line. For example:

```html
---
variableName: value
arrayVariable:
    - arrayValue 1
    - arrayValue 2
---
```

### Standard metadata

The system relies upon an **id** variable and **title** variable to be present in all pages in order to build its tree and perform cross referencing tasks. It will also allow you to tag pages with categories and 'related' links.

A full example might look like:

```html
---
id: function-abs
title: Abs()
related:
    - "[Problem with Abs()](http://someblog.com/somearticle.html)"
categories:
    - number
    - math
```

Category links will be rendered as ```[[category-categoryname]]```. Related links will be rendered using the markdown renderer so can use any valid link format, including our custom cross referencing syntax (see above, and note the required double quotes to escape the special characters).

