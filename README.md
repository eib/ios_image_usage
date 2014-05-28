ios_image_usage
===============

Creates usage reports on image files in your Xcode project.

Usage
=====

```bash
cd path/to/xcode-workspace/
path/to/ios_image_usage.rb > image_results.txt
less < image_results.txt
```

Reported Issues
===============
* Missing images: image filenames referenced in code/resources that could not be found
* Missing references: images that do not have any references in code/resources
* Missing Retina versions: images with missing Retina versions ("@2x.png")
* Missing non-Retina versions: images with _only_ Retina versions
* Missing iPhone versions: _only_ iPad versions exist ("~iPad.png")
* Missing iPad versions: _only_ iPhone versions exist ("~iPhone.png")
* Duplicate files: files with the same name in different locations
