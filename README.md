# Loki

Loki is a quick and dirty utility to build static web pages using a
simple templating format.

## Getting Started

To get started, run the following command (you'll need to the bundler gem):

```
bundle install
```

To install the gem, run the following commands (optionally replacing
`*` with the current version):

```
gem build loki.gemspec
gem install loki-*.gem
```

You can then run the loki command anywhere like this:

```
loki <source-dir> <destination-dir>
```

If you don't want to install the gem, you can alternately run loki
from the loki repository directory like so:

```
bin/loki <source-dir> <destination-dir>
```

If you'd like to run the tests, run:

```
rspec
```

There's also a pretty primitive Makefile that does all this for you
(as well as `make clean` which will uninstall and remove the gem).

## Using Loki

Loki requires a source and destination directory, and both of these
paths must exist before running loki.  In addition, the source
directory must contain the `views`, `assets`, and `components`
directories before loki will run.

The `views` directory contains the pages generated by loki.

The `assets` directory contains any other objects (images, scripts,
css, any other random files) referred to in those pages.  Any assets
will be copied to the destination directory if (and only if)
referenced by a page.

The `components` directory contains any components (templates,
partials) needed to build the pages.

## Loki Pages

Loki pages have two sections, metadata and body separated by two
dashes (`--`) on a line all by itself.  Bodies can contain any
arbitrary HTML and directives (see below) enclosed in curly braces
(`{` and `}`).  For example, a page might look like:

```
id "home"
title "my home page"
css ["css/default.css"]
--
{include("partials/header.prt")}

<h1>This is my home page</h1>

Today is {Time.now}.

{link("about", "About Me", {class: "my-link"})}
{include("partials/footer.prt")}
```

This might end up looking something like:

```
<html>
<head>
  <title>my home page</title>
  <link rel="stylesheet" href="assets/css/default.css" type="text/css" />
</head>
<body>
<b>my header</b>

<h1>This is my home page</h1>

Today is 2016-03-28 00:05:56 -0600.

<a href="/about.html" class="my-link">About Me</a>
<i>my footer</i>
</body>
</html>
```

## Metadata Parameters

The following parameters are available:

* `id`: page id; must be unique. This is used to reference other pages
  with the link directive (see below).

* `title`: page title (will go in the head).

* `template`: template used for this page (if set). The template must
  exist with the filename supplied in the `components` directory.

* `tags`: a list of tags

* `css`: a list of css files; the files must exist in the `assets`
  directory and will be copied when referenced.

* `javascript`: a list of javascript files; the files must exist in
  the `assets` directory and will be copied when referenced.

* `set`: custom metadata fields; requires two arguments: a key and a
  value. For example, if `set :foo, "bar"` is used in a page's
  metadata, `{page.foo}` in the body would insert `bar` into the
  page at that point.

Values must be inside strings (they are interpreted as ruby strings;
values can also be returned from a `do`-`end` block).  You can also
put arbitrary ruby code in the metadata, e.g., `{Time.now.year}` would
insert the year at that point in the page.

## Loki Directives

Any blocks of ruby code can be inserted inside of curly brackets
(`{}`) in page bodies.  This can be used to calculate values or insert
dates, etc.  The following directives are also available in the
interpretation scope:

* `body`: only legal in templates, will include the page body (this is
  required somewhere in the template for it to function)

* `page`: the current page object; this can be used to access values
  set in metadata.  For example `{page.id}` would insert the value of
  the current page's `id` into the body.

* `site`: same as above, only for global site values.

* `include(<partial>)`: includes another file from the components
  directory

* `link(<id/path>, <text>)`: inserts a link to another page or asset;
  pages are referred by id, assets by path (don't include the 'asset'
  directory in the path, that will be prepended automatically).  Text
  will be the text of the link (or HTML or whatever).  Assets must
  exist in the source assets directory and will be copied to the
  destination directory.

* `link_abs(<url>, <text>)`: inserts an arbitrary absolute link.  Text
  is same as above.

* `image(<path>)`: inserts an image.  Image must exist in source
  assets directory and will be copied to the destination directory.

`link`, `link_abs`, and `image` can be passed an options hash as the
last argument; an `:id` key is used for ids, `:class` for classes, and
`:style` for styles.  Passing the option `:self_class` to links will
instruct them to use the supplied class if the link points to itself.
Passing the option `:append` will append the value to the link, i.e.,
something like `#top` could be appended to the end of the url to link
to the id `top` inside a page.  Using a double open curly brace (`{{`)
will result in a literal curly brace (`{`) in the destination file.
Using a double close curly brace (`}}`) inside an evaluation context
will be a literal curly brace (`}`) instead of closing the context.

## To Do

Need something to add to to do
