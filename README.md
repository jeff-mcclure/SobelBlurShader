------------------------------------------------------------------------------
# Sobel No Bleed Blur Shader (realfargoth)
------------------------------------------------------------------------------
This shader darkens edges present in the scene by using the **Sobel** operator. Optionally, it **blurs** the colors in the
scene for a watercolor-like effect. The blurring is sensitive to edges in the scene in order to minimize color bleeding
across different textures.

It is recommended to place this shader following anti-aliasing shaders in your shader chain. It is recommended to
configure the variables in the shader to your taste. Disable blur if performance is an issue.

The basis for this mod is derived from previously available watercolor shaders, credit to all those who ported and added
functionality to these shaders: Kamikaze, zilav, wazabear, urm.

The previous watercolor shader caused issues with the visuals due to the blur it applied. This shader is configurable such that 
blur may be disabled, and if enabled the blur is dampened across edges in the scene (this minimizes blurring causing colors
to bleed across one another in high gradient areas such as NPC faces/eyes, or other fine detail areas). The application of
the Sobel operator is also improved by applying it across RGB color channels separately, and the option of using a larger stencil
size for the operator.

The LQ Blur is derived from a kawase blur method ported to openMW by Epoch.

Shader tested using the OpenMW dev build v0.49 and MGEXE v0.17.0 + MWSE v2.1.0.

------------------------------------------------------------------------------
## Configurable Variables
------------------------------------------------------------------------------
**Enable Blur**:          (default: ON) Enable/Disable edge-preserving blur effect. 
**Enable Sobel Filter**:  (default: ON) Enable/Disable the Sobel filter that darkens edges. 
**Exclude Sky**:          (default: ON) Exclude sky from Sobel filter (edges of stars in the night sky can look weird).

**Edge Color Amount**:    (default: 1.5) Increase/Decrease the intensity at which the Sobel edges are darkened.
**Detail**:               (default: 0.75) Increase/Decrease the intensity at which the pixel color is mixed with the darkened Sobel edges.
**Detail Exponent**:      (default: 1.0) A lower exponent picks up fine details more.
**5x5 Sobel**:            (default: ON) Enable/Disable a larger stencil Sobel filter for smoother results.
**RGB Sobel**:            (default: ON) Enable/Disable application of the Sobel filter on separate color channels. Detects edges better. 

**Enable HQ Blur**:       (default: ON) Enable/Disable computing the edge-preserving blur with true Gaussian weights.
**Local Var Threshold**   (default: 3.5) Higher values suppress blurring across texture edges. 
**Blur Radius**:          (default: 1.5) Larger values increase the amount of blurring.
**LQ Blend Strength**:    (default: 0.8) Blurred image blending fraction with the scene (negative values sharpen the image). Only relevant is Enable HQ Blur is OFF.

**Show Sobel Edges**:     (default: OFF) When ON, shows only the Sobel filter results.

------------------------------------------------------------------------------
## Alternate Recommended Configurations
------------------------------------------------------------------------------
1. Minimal Effect Changes:
	Enable Blur: **OFF**, Edge Color Amount: **0.5**, Detail: **1.0**, Detail Exponent: **1.1**

2. Stronger Effect Changes:
	Edge Color Amount: **2.5**, Detail: **0.5**, Blur Radius: **3**
	
3. Performance Changes:
	Enable Blur: **OFF**, or Enable HQ Blur: **OFF**

------------------------------------------------------------------------------
## Installing (OpenMW)
------------------------------------------------------------------------------
*Ensure that you have the [latest development build](https://openmw.org/downloads/) of OpenMW.

1. Extract the archive to the path you keep your OpenMW mods.
2. Add the path to the folder you extracted to your openmw.cfg file, load order doesn't matter:
```
data = "path/SobelBlurShader"
```
3. Enable post-processing shaders in your `settings.cfg`.
4. Open the in-game 'Options' menu and enable 'Post Processing' in the 'Video' tab.
5. Press F2 to open the in-game post-processing menu.
6. Double-click on 'Sobel Blur'.
7. If you are using other shaders, move Sobel Blur so that it follows anti-aliasing in your shader-chain (EdgeAA, FXAA, etc.).
8. Configure the variables listed in ## Configurable Variables to your preference.

------------------------------------------------------------------------------
## Installing (MGEXE)
------------------------------------------------------------------------------
1. Copy the shaders folder into your Data Files directory located in your Morrowind root directory.
2. Open MGEXEgui.exe in your Morrowind root directory.
3. On the Graphics tab, ensure Enable Shaders is selected.
4. Click on Shader setup...
5. Click on Modding > > > 
6. Double-click on Sobel Blur under Available shaders.
7. Move Sobel Blur so that if follows any anti-aliasing in your shader-chain (EdgeAA, FXAA, etc.).
8. Configure the variables listed in ## Configurable Variables to your preference.

------------------------------------------------------------------------------
## Known issues
------------------------------------------------------------------------------
- Performance hit if using HQ Blur at large blur radii

