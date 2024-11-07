static const bool uEnableBlur = true;
static const bool uEnableSobel = true;
static const float uEdgeColorAmount = 1.5; // typical range 0.5 -> 5.0
static const float uDetail = 0.75; // typical range 0 -> 1.0
static const float uDetailExp = 1.0; // typical range 0.7 -> 1.5
static const bool uLargeSobel = true;
static const bool uEnableRGBSobel = true;
static const bool uEnableHQBlur = true;
static const float uGradThres = 3.5; // typical range 1.5 -> 5.0
static const float uBlurR = 1.5; // must be a multiple of 0.5 between 0.5 -> 6.0
static const float uStrength = 0.8; // typical range -1.0 -> 1.0
static const bool uEnableGrad = false;

float3 eyepos;
float3 eyevec;
float2 rcpres;
float fov;
float waterlevel;

texture lastshader;
texture depthframe;
texture lastpass;
sampler s0 = sampler_state { texture=<lastshader>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s1 = sampler_state { texture=<depthframe>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };
sampler s2 = sampler_state { texture=<lastpass>; addressu = clamp; addressv = clamp; magfilter = point; minfilter = point; };

static const float w0_n[12] = {0.6187,0.1592,0.0733,0.0417,0.0269,0.0202,0.0148,0.0124,0.0096,0.0077,0.0068,0.0056};
static const float3 grayscale = float3(0.3, 0.59, 0.11);

float4 gscale(float4 x) 
{
	return float4(0,0,0,dot(x.rgb, grayscale));
}

float4 GetPixelColor(float2 uv, bool is_rgb)
{
	if (is_rgb) {
		return tex2D(s0, uv);
	}
	return gscale(tex2D(s0, uv));
}

float4 EdgeSmartMix(float4 cColor, float4 mColor)
{
	float diff = abs(cColor.r - mColor.r) + abs(cColor.g - mColor.g) + abs(cColor.b - mColor.b);
	float fac = saturate(pow(diff*4*uGradThres,3));
	return mColor*(1 - fac) + cColor*(fac);
}

//pixel step vectors

static float2 xdisp = float2( 1.0, 0.0) * rcpres;
static float2 ydisp = float2( 0.0, 1.0) * rcpres;

static const float xylength = sqrt(1 - eyevec.z * eyevec.z);
static const float t   = 2.0 * tan(radians(fov * 0.5));
static const float ty  = t / rcpres.y * rcpres.x;
static const float sky = 1e6;


float3 toView(float2 uv)
{
    float depth = tex2D(s1, uv).r;
    float x = 0; //(uv.x - 0.5) * depth * t;
    float y = (uv.y - 0.5) * depth * ty;
    return float3(x, y, depth);
}

float4 sobel(float2 uv : TEXCOORD0) : COLOR0
{
    float4 pixelColor = tex2D(s2, uv);

    // exclude sky and water
	
    float3 pos = toView(uv);
    float water = pos.z * eyevec.z - pos.y * xylength + eyepos.z;
    if(pos.z <= 0 || pos.z > sky || (water - waterlevel) < 0) return pixelColor;
	
	// intensity gradients
	
	float dX = 0.0;
	float dY = 0.0;
	float grad = 0.0;
	
	// grab surrounding px colors and apply Sobel operator	
	
	if (uEnableSobel){
		float4 sw = GetPixelColor(uv - xdisp - ydisp, uEnableRGBSobel);
		float4 w = GetPixelColor(uv - xdisp, uEnableRGBSobel);
		float4 nw = GetPixelColor(uv - xdisp + ydisp, uEnableRGBSobel);
		float4 s = GetPixelColor(uv - ydisp, uEnableRGBSobel);
		float4 n = GetPixelColor(uv + ydisp, uEnableRGBSobel);
		float4 se = GetPixelColor(uv + xdisp - ydisp, uEnableRGBSobel);
		float4 e = GetPixelColor(uv + xdisp, uEnableRGBSobel);
		float4 ne = GetPixelColor(uv + xdisp + ydisp, uEnableRGBSobel);
		
		if (uLargeSobel){
			float4 nn = GetPixelColor(uv + ydisp*2, uEnableRGBSobel);
			float4 nne = GetPixelColor(uv + ydisp*2 + xdisp, uEnableRGBSobel);
			float4 nnee = GetPixelColor(uv + ydisp*2 + xdisp*2, uEnableRGBSobel);
			float4 nnw = GetPixelColor(uv + ydisp*2 - xdisp, uEnableRGBSobel);
			float4 nnww = GetPixelColor(uv + ydisp*2 - xdisp*2, uEnableRGBSobel);
			float4 ss = GetPixelColor(uv - ydisp*2, uEnableRGBSobel);
			float4 sse = GetPixelColor(uv - ydisp*2 + xdisp, uEnableRGBSobel);
			float4 ssee = GetPixelColor(uv - ydisp*2 + xdisp*2, uEnableRGBSobel);
			float4 ssw = GetPixelColor(uv - ydisp*2 - xdisp, uEnableRGBSobel);
			float4 ssww = GetPixelColor(uv - ydisp*2 - xdisp*2, uEnableRGBSobel);
			float4 ee = GetPixelColor(uv + xdisp*2, uEnableRGBSobel);
			float4 een = GetPixelColor(uv + ydisp + xdisp*2, uEnableRGBSobel);
			float4 ees = GetPixelColor(uv - ydisp + xdisp*2, uEnableRGBSobel);
			float4 ww = GetPixelColor(uv - xdisp*2, uEnableRGBSobel);
			float4 wwn = GetPixelColor(uv + ydisp - xdisp*2, uEnableRGBSobel);
			float4 wws = GetPixelColor(uv - ydisp - xdisp*2, uEnableRGBSobel);
			if (uEnableRGBSobel) {
				float dX_r = (-10.0*ww.r - 20.0*w.r + 20.0*e.r + 10.0*ee.r - 8.0*wwn.r - 8.0*wws.r - 10.0*sw.r - 10.0*nw.r + 10.0*ne.r + 10.0*se.r + 8.0*een.r + 8.0*ees.r - 5.0*nnww.r - 5.0*ssww.r - 4.0*nnw.r - 4.0*ssw.r + 4.0*nne.r + 4.0*sse.r + 5.0*nnee.r + 5.0*ssee.r)/30;
				float dY_r = (-10.0*ss.r - 20.0*s.r + 20.0*n.r + 10.0*nn.r - 8.0*sse.r - 8.0*ssw.r - 10.0*sw.r + 10.0*nw.r + 10.0*ne.r - 10.0*se.r + 8.0*nnw.r + 8.0*nne.r + 5.0*nnww.r - 5.0*ssww.r + 4.0*wwn.r - 4.0*wws.r + 4.0*een.r - 4.0*ees.r + 5.0*nnee.r - 5.0*ssee.r)/30;				
				float dX_g = (-10.0*ww.g - 20.0*w.g + 20.0*e.g + 10.0*ee.g - 8.0*wwn.g - 8.0*wws.g - 10.0*sw.g - 10.0*nw.g + 10.0*ne.g + 10.0*se.g + 8.0*een.g + 8.0*ees.g - 5.0*nnww.g - 5.0*ssww.g - 4.0*nnw.g - 4.0*ssw.g + 4.0*nne.g + 4.0*sse.g + 5.0*nnee.g + 5.0*ssee.g)/30;
				float dY_g = (-10.0*ss.g - 20.0*s.g + 20.0*n.g + 10.0*nn.g - 8.0*sse.g - 8.0*ssw.g - 10.0*sw.g + 10.0*nw.g + 10.0*ne.g - 10.0*se.g + 8.0*nnw.g + 8.0*nne.g + 5.0*nnww.g - 5.0*ssww.g + 4.0*wwn.g - 4.0*wws.g + 4.0*een.g - 4.0*ees.g + 5.0*nnee.g - 5.0*ssee.g)/30;				
				float dX_b = (-10.0*ww.b - 20.0*w.b + 20.0*e.b + 10.0*ee.b - 8.0*wwn.b - 8.0*wws.b - 10.0*sw.b - 10.0*nw.b + 10.0*ne.b + 10.0*se.b + 8.0*een.b + 8.0*ees.b - 5.0*nnww.b - 5.0*ssww.b - 4.0*nnw.b - 4.0*ssw.b + 4.0*nne.b + 4.0*sse.b + 5.0*nnee.b + 5.0*ssee.b)/30;
				float dY_b = (-10.0*ss.b - 20.0*s.b + 20.0*n.b + 10.0*nn.b - 8.0*sse.b - 8.0*ssw.b - 10.0*sw.b + 10.0*nw.b + 10.0*ne.b - 10.0*se.b + 8.0*nnw.b + 8.0*nne.b + 5.0*nnww.b - 5.0*ssww.b + 4.0*wwn.b - 4.0*wws.b + 4.0*een.b - 4.0*ees.b + 5.0*nnee.b - 5.0*ssee.b)/30;				
				dX = sqrt((dX_r*dX_r + dX_g*dX_g + dX_b*dX_b)/3);
				dY = sqrt((dY_r*dY_r + dY_g*dY_g + dY_b*dY_b)/3);
			}
			else {		
				dX = (-10.0*ww.a - 20.0*w.a + 20.0*e.a + 10.0*ee.a - 8.0*wwn.a - 8.0*wws.a - 10.0*sw.a - 10.0*nw.a + 10.0*ne.a + 10.0*se.a + 8.0*een.a + 8.0*ees.a - 5.0*nnww.a - 5.0*ssww.a - 4.0*nnw.a - 4.0*ssw.a + 4.0*nne.a + 4.0*sse.a + 5.0*nnee.a + 5.0*ssee.a)/30;
				dY = (-10.0*ss.a - 20.0*s.a + 20.0*n.a + 10.0*nn.a - 8.0*sse.a - 8.0*ssw.a - 10.0*sw.a + 10.0*nw.a + 10.0*ne.a - 10.0*se.a + 8.0*nnw.a + 8.0*nne.a + 5.0*nnww.a - 5.0*ssww.a + 4.0*wwn.a - 4.0*wws.a + 4.0*een.a - 4.0*ees.a + 5.0*nnee.a - 5.0*ssee.a)/30;							
			}
		}
		else {
			if (uEnableRGBSobel) {
				float dX_r = -sw.r - 2.0*w.r - nw.r + se.r + 2.0*e.r + ne.r;
				float dY_r = -sw.r - 2.0*s.r - se.r + nw.r + 2.0*n.r + ne.r;	
				float dX_g = -sw.g - 2.0*w.g - nw.g + se.g + 2.0*e.g + ne.g;
				float dY_g = -sw.g - 2.0*s.g - se.g + nw.g + 2.0*n.g + ne.g;	
				float dX_b = -sw.b - 2.0*w.b - nw.b + se.b + 2.0*e.b + ne.b;
				float dY_b = -sw.b - 2.0*s.b - se.b + nw.b + 2.0*n.b + ne.b;	
				dX = sqrt((dX_r*dX_r + dX_g*dX_g + dX_b*dX_b)/3);
				dY = sqrt((dY_r*dY_r + dY_g*dY_g + dY_b*dY_b)/3);	
			}
			else {
				dX = -sw.a - 2.0*w.a - nw.a + se.a + 2.0*e.a + ne.a;
				dY = -sw.a - 2.0*s.a - se.a + nw.a + 2.0*n.a + ne.a;	
			}
		}
		
		grad = pow(saturate(0.3*sqrt((dX*dX) + (dY*dY))), uDetailExp);
	}
	
	// debug show Sobel edge detection
	
	if (uEnableGrad) {
		return float4(grad, grad, grad, 1.0);
	}
	
	// apply blur
	
	float4 outcolor = float4(0.0,0.0,0.0,0.0);
	
	if (uEnableHQBlur && uEnableBlur) {
		float4 blurColor = float4(0.0,0.0,0.0,0.0);
		float4 curColor = float4(0.0,0.0,0.0,0.0);
		int kernel = int(ceil(1.25*uBlurR+1));
		float w0 = w0_n[int(uBlurR/0.5 - 1)];
		
		for (int i = 0; i < kernel*2 + 1; i++) {
			for (int j = 0; j < kernel*2 + 1; j++) {
				curColor = tex2D(s0, uv.xy + float(i - kernel)*xdisp + float(j - kernel)*ydisp);
				float diff = abs(pixelColor.r - curColor.r) + abs(pixelColor.g - curColor.g) + abs(pixelColor.b - curColor.b);
				float fac = saturate(pow(diff*uGradThres,3));
				blurColor += (curColor*(1 - fac) + pixelColor*(fac))*(w0*exp(-(pow(float(i - kernel), 2) + pow(float(j - kernel), 2))/(2.0*uBlurR*uBlurR)));
			}
		}
		outcolor = ((-grad*uEdgeColorAmount + 10*grad*blurColor*(1 - uDetail)) + blurColor);
	}
	else {
		outcolor = ((-grad*uEdgeColorAmount + 10*grad*pixelColor*(1 - uDetail)) + pixelColor);
	}
	
	outcolor.a = pixelColor.a;

    return outcolor;
}

float4 downsample(float2 uv : TEXCOORD0) : COLOR0
{
	if (uEnableHQBlur || !uEnableBlur) {
		return tex2D(s2, uv);
	}
	float2 uv_scaled = uv*1.5;
	float2 halfpixel = 0.5*rcpres/(1/1.5);
	float4 pixelColor = tex2D(s2, uv_scaled);
	
	float4 sum = pixelColor*4.0;
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled  - halfpixel.xy * uBlurR/2));
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled  + halfpixel.xy * uBlurR/2));
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled  + float2(halfpixel.x, -halfpixel.y) * uBlurR/2));
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled  - float2(halfpixel.x, -halfpixel.y) * uBlurR/2));

	return sum/8.0;
}

float4 upsample(float2 uv : TEXCOORD0) : COLOR0
{	
	if (uEnableHQBlur || !uEnableBlur) {
		return tex2D(s2, uv);
	}
	float2 uv_scaled = uv/1.5;
	float2 halfpixel = 0.5*rcpres/(1.5);
	float4 pixelColor = tex2D(s2, uv_scaled);
	
	float4 sum = EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(-halfpixel.x * 2.0, 0.0) * uBlurR/2));	
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(-halfpixel.x, halfpixel.y) * uBlurR/2))*2.0;
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(0.0, halfpixel.y * 2.0) * uBlurR/2));
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(halfpixel.x, halfpixel.y) * uBlurR/2))*2.0;	
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(halfpixel.x * 2.0, 0.0) * uBlurR/2));
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(halfpixel.x, -halfpixel.y) * uBlurR/2))*2.0;	
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(0.0, -halfpixel.y * 2.0) * uBlurR/2));
	sum += EdgeSmartMix(pixelColor, tex2D(s2, uv_scaled + float2(-halfpixel.x, -halfpixel.y) * uBlurR/2))*2.0;	

	return sum/12.0;
}

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
	if (uEnableHQBlur || !uEnableBlur){
		return tex2D(s2, uv);
	}
	
	float4 scene = tex2D(s0, uv);
	float4 blur = tex2D(s2, uv);
	
	return scene*(1 - uStrength) + blur*uStrength;
}

technique T0 < string MGEinterface="MGE XE 0"; >
{	
	pass { PixelShader = compile ps_3_0 downsample(); }
	pass { PixelShader = compile ps_3_0 downsample(); }
	pass { PixelShader = compile ps_3_0 upsample(); }
	pass { PixelShader = compile ps_3_0 upsample(); }
	pass { PixelShader = compile ps_3_0 main(); }
    pass { PixelShader = compile ps_3_0 sobel(); }
}
