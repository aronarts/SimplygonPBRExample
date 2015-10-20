# Simplygon PBR Example
==================================

## Introduction
This example shows how you can cast custom shaders using Simplygon through the Maya plugin.

## Requirements
- Simplygon 7.0.1441 or greater.
- Only tested in Maya 2016, might work in 2015 as well.

## Content
- Simplygon Man as a Maya 2016 file with PBR materials (Assets/simplygon_man_PBR.mb)
- Cgfx shader file (Shader/SimplygonPBRShader.fx)
- Simplygon start up script (Scripts/SimplygonPBRScript_MultiMat.mel)
This script shows how the shading network is described to Simplygon before the application is launched. For more information, you can look here: [CGFX and Simplygon tutorial](https://www.simplygon.com/knowledge-base/tutorials/shading-networks-in-maya-for-cgfx-shaders)
- A couple of settings files that you can use to test the results (in the Settings folder)

## Getting started
- You need to replace the root variable at the top of SimplygonPBRScript_MultiMat.mel to point the location you have the example.
- When you load the character it will most likely be green, the shader path needs to be updated to the correct location for all materials.
- Copy the content of the mel script and add it as a shelf command for easy access.

## Test cases
Here are few ideas of what you can try:
- 4 step lod chain with 50% reduction, where you bake the material on the third step. You don't need to bake the material again on the fourth step as it will use the previous one.
- A proxy lod
- A aggregated version of the asset.

## Known issues
- The results in the Simplygon interface are significantly darker than the input. However, this is just a color management issue in the renderer. The source textures are ok. 
- There are some errors when loading the shaders, never mind them. It's work in progress.
- The asset is overbright with Maya's srgb gamma turned on. If you set it to raw instead it will look better.

