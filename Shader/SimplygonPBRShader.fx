/*********************************************************************NVMH3****
Simplygon PBR Shader
******************************************************************************/

// UNTweakables /////////////////////

float4x4 WorldITXf : WorldInverseTranspose;
float4x4 WVPXf : WorldViewProjection;
float4x4 WorldXf : World;
float4x4 Viewf : View;
float4x4 ViewIXf : ViewInverse;

///////////////////


texture CubemapTexture : Cubemap
<
	string ResourceType = "Cube";
	string UIName =  "Cubemap Texture";
>;

texture DiffuseTexture : Diffuse
<
	string ResourceType = "2D";
	string UIName =  "Diffuse Texture";
>;

texture SpecularTexture : Specular
<
	string ResourceType = "2D";
	string UIName =  "Specular Texture";
>;

texture RoughnessTexture : Specular
<
	string ResourceType = "2D";
	string UIName =  "Roughness Texture";
>;

texture MetallnessTexture : Specular
<
	string ResourceType = "2D";
	string UIName =  "Metalness Texture";
>;

texture NormalTexture : Normal
<
	string ResourceType = "2D";
	string UIName =  "Normal Texture";
>;

samplerCube CubemapSampler = sampler_state 
{
	Texture = <CubemapTexture>;
	MinFilter = LinearMipMapLinear;
	MagFilter = Linear;
	WrapR = ClampToEdge;
	WrapS = ClampToEdge;
	WrapT = ClampToEdge;
};

sampler2D DiffuseSampler = sampler_state 
{
	Texture = <DiffuseTexture>;
	MinFilter = LinearMipMapLinear;
	MagFilter = Linear;
};

sampler2D SpecularSampler = sampler_state 
{
	Texture = <PBRSpecularTexture>;
	MinFilter = LinearMipMapLinear;
	MagFilter = Linear;
};

sampler2D RoughnessSampler = sampler_state 
{
	Texture = <RoughnessTexture>;
	MinFilter = LinearMipMapLinear;
	MagFilter = Linear;
};

sampler2D MetalnessSampler = sampler_state 
{
	Texture = <MetallnessTexture>;
	MinFilter = LinearMipMapLinear;
	MagFilter = Linear;
};

sampler2D NormalsSampler = sampler_state 
{
	Texture = <NormalTexture>;
	MinFilter = LinearMipMapLinear;
	MagFilter = Linear;
};

////////////////////

struct appdata 
{
	float3 Position	 : POSITION;
	float4 UV		 : TEXCOORD0;
	float3 Normal	 : NORMAL;
	float3 Tangent	 : TANGENT;
	float3 Bitangent : BINORMAL;
};

struct vertexOutput 
{
	float4 HPosition		: POSITION;
	float4 TexCoord			: TEXCOORD0;
	float3 VertexNormal		: TEXCOORD1;
	float3 VertexTangent	: TEXCOORD2;
	float3 VertexBitangent	: TEXCOORD3;
	float3 ViewDir			: TEXCOORD4;
};

////////////////////////////////////
////////////////////////////////////


float schlick(float r0, float a)
{
	return r0 + (1.0-r0)*pow(1.0-a, 5.0);
}

float dotp( float3 a , float3 b )
{
	return a.x*b.x + a.y*b.y + a.z*b.z;
}

float3 SampleCubeMap(float x, float3 dir)
{
	return texCUBE(CubemapSampler, dir).rgb;
	//return float3(1,1,1);
//    x *= 3.0;
//    //dir.z = dir.z * -1.0;
//    float3 color;
//    if (x < 1.0)
//	{
//		color = (1.0-x)*decodeRGBE8(CUBEMAP1_TEXTURE.Sample(CUBEMAP1_TEXTURE_SAMPLER, dir)).rgb + x*decodeRGBE8(CUBEMAP2_TEXTURE.Sample(CUBEMAP2_TEXTURE_SAMPLER, dir)).rgb;
//    } 
//	else if (x >= 1.0 && x < 2.0)
//	{
//		color = (1.0-(x-1.0))*decodeRGBE8(CUBEMAP2_TEXTURE.Sample(CUBEMAP2_TEXTURE_SAMPLER, dir)).rgb + (x-1.0)*decodeRGBE8(CUBEMAP3_TEXTURE.Sample(CUBEMAP3_TEXTURE_SAMPLER, dir)).rgb;
//   } 
//	else if (x >= 2.0) 
//	{
//		color = (1.0-(x-2.0))*decodeRGBE8(CUBEMAP3_TEXTURE.Sample(CUBEMAP3_TEXTURE_SAMPLER, dir)).rgb + (x-2.0)*decodeRGBE8(CUBEMAP4_TEXTURE.Sample(CUBEMAP4_TEXTURE_SAMPLER, dir)).rgb;
//    }
//    return color;
}

float3 brdf(float3 outdir, float3 normal, float3 baseColor, float3 params)
{
    float3 refdir = reflect(-outdir, normal);

    float F0 = params.x*params.x;
    float odotn = max(0.0, dot(outdir, normal));
    float fresnel = schlick(F0, odotn);

    float3 diffuseRef = SampleCubeMap(0.0, normal);
    float3 specularRef = SampleCubeMap(1.0-params.y, refdir);
    float specAmount = (1.0-params.y) * fresnel;
    float3 dielectric = (1.0 - 0.25*specAmount) * baseColor * diffuseRef + 0.25 * specAmount * specularRef;

    float3 midSpecularRef = SampleCubeMap( (1.0-params.y)*(1.0-params.y), refdir );
    float b = schlick(0.0, odotn);
    float3 metal = fresnel * (b*float3(1.0, 1.0, 1.0) + (1.0-b)*baseColor) * (params.y * midSpecularRef + (1.0-params.y) * specularRef);

    return params.z * metal + (1.0-params.z) * dielectric;
}

float4 ComputePBRShading(float3 vertexNormal,
						 float3 vertexTangent,
						 float3 vertexBitangent,
						 float3 viewDir, 
						 float3 lightDir, 
						 float2 texCoord)
{
	float4 finalColor = float4(1.0, 1.0, 1.0, 1.0);

	float3 diffuse = tex2D(DiffuseSampler, texCoord).rgb;
	float specular = saturate(1.0*tex2D(SpecularSampler, texCoord).r);
	float roughness = saturate(1.0*tex2D(RoughnessSampler, texCoord).r);
	float metalness = saturate(1.0*tex2D(MetalnessSampler, texCoord).r);
	
	float3 pbrSpecular = float3(specular, roughness, metalness);
	
	float3 normal = (tex2D(NormalsSampler, texCoord).rgb * 2.0f) - float3(1,1,1);
    	
	float3x3 TBN =  float3x3( vertexTangent, vertexBitangent, vertexNormal );
	normal = normalize( mul(normal, TBN) );
		
    float3 light = brdf(viewDir, normal, diffuse, pbrSpecular) * 0.6;//* exposure * ao_color.rgb;

    light.xyz = max(light.xyz - 0.004, 0.0);
    light.xyz = (light.xyz * (6.2*light.xyz + 0.5)) / (light.xyz * (6.2*light.xyz + 1.7) + 0.06);
    
    finalColor.rgb = light;

	return finalColor;
}


////////////////////////////////////

vertexOutput mainVS(appdata IN) 
{
    vertexOutput OUT;
   
    float4 Po = float4(IN.Position.xyz,1);
    float3 Pw = mul(WorldXf, Po).xyz;
	
	OUT.HPosition = mul(WVPXf, Po);
	OUT.VertexNormal = mul(WorldITXf, float4(IN.Normal,0)).xyz;
	OUT.VertexTangent = mul(WorldITXf, float4(IN.Tangent,0)).xyz;
	OUT.VertexBitangent = mul(WorldITXf, float4(IN.Bitangent,0)).xyz;
    OUT.TexCoord = IN.UV;
    OUT.ViewDir = normalize(float3(Viewf[2].x, Viewf[2].y, Viewf[2].z));
    
    return OUT;
}

float4 mainPS(vertexOutput IN) : COLOR 
{
	
	float3 vertexNormal = normalize(IN.VertexNormal);
	float3 vertexTangent = normalize(IN.VertexTangent);
	float3 vertexBitangent = normalize(IN.VertexBitangent);
	float3 viewDir = normalize(IN.ViewDir);
	float3 lightDir = normalize(IN.ViewDir);		

	viewDir = float3(-viewDir.x, -viewDir.y, viewDir.z);
	
	return ComputePBRShading(vertexNormal,
							 vertexTangent,
							 vertexBitangent,
							 viewDir,
							 lightDir, 
							 IN.TexCoord.xy);
}

/*************/
  
technique PBR < string Script = "Pass=p0;"; > 
{
	pass p0 < string Script = "Draw=geometry;"; > 
	{
		VertexProgram = compile arbvp1 mainVS();
		DepthTestEnable = true;
		DepthMask = true;
		CullFaceEnable = false;
		DepthFunc = LEqual;
		FragmentProgram = compile arbfp1 mainPS();
	}
}