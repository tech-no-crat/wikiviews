# WikiViews

A node module that will download view counts for a wikipedia article between any two dates.

Use it like this:

```
WikiViews = require('wikiviews');

WikiViews('Bitcoin', '201004', '201206', function(data) {
  console.log("Got data");
});
```

The second and third arguments are the start and month respectively, so the above code will download data for the wikipedia article on Bitcoin starting from April 2010 to June 2012.
