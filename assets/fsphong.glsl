#version 400

in vec3 Position;
in vec3 Normal;
in vec2 Texcoord;
in vec3 Tangent;
in vec3 Bitangent;

out vec4 FragColor;

/*
uniform vec3 LightPos;
uniform vec3 LightColor;
 */

uniform vec3 EyePos;
uniform vec3 DiffuseColor;
uniform vec3 SpecularColor;
uniform vec3 AmbientColor;
uniform float SpecularExp;
uniform sampler2D DiffuseTexture;
uniform sampler2D NormalTexture;

const int MAX_LIGHTS=14;
struct Light
{
    int Type;
    vec3 Color;
    vec3 Position;
    vec3 Direction;
    vec3 Attenuation;
    vec3 SpotRadius;
    int ShadowIndex;
};

uniform Lights
{
    int LightCount;
    Light lights[MAX_LIGHTS];
};

float sat( in float a)
{
    return clamp(a, 0.0, 1.0);
}

void main()
{

    mat3 NormalMat = mat3(Tangent, Bitangent, Normal);
    vec4 NormalText = texture(NormalTexture, Texcoord);
    vec3 NormalFromNormalMap = vec3(NormalText.r * 2 - 1, NormalText.g * 2 - 1, NormalText.b * 2 - 1);
    vec3 NewNormal = NormalMat * NormalFromNormalMap;

    vec3 FColor = vec3(0,0,0);

    vec4 DiffTex = texture( DiffuseTexture, Texcoord);
    if(DiffTex.a <0.3f) discard;

    // vec3 N = normalize(Normal);
    vec3 N = normalize(NewNormal);
    vec3 E = normalize(EyePos-Position);
    
    for(int i=0; i<LightCount; i++) {
        if(lights[i].Type == 0) {
            
            //POINT
            vec3 L = normalize(lights[i].Position-Position);
            vec3 R = reflect(-L,N);
            vec3 H = normalize(L+E);
            
            vec3 LightColor = lights[i].Color;
            float dist = sqrt( pow((lights[i].Position-Position).x, 2) + pow((lights[i].Position-Position).y, 2) + pow((lights[i].Position-Position).z, 2) );
            float att = 1.0/( lights[i].Attenuation.x + lights[i].Attenuation.y * dist + lights[i].Attenuation.z * dist * dist );
            
            vec3 DiffuseComponent = att * LightColor * DiffuseColor * sat(dot(N,L));
            vec3 SpecularComponent = att * LightColor * SpecularColor * pow( sat(dot(N,H)), SpecularExp);
            FColor += vec3(DiffuseComponent*DiffTex.rgb + SpecularComponent);
            //FragColor = vec4((DiffuseComponent + AmbientColor)*DiffTex.rgb + SpecularComponent ,DiffTex.a);
            
        } else if(lights[i].Type == 1) {
            
            //DIRECTIONAL
            vec3 L = normalize(-lights[i].Direction);
            vec3 R = reflect(-L,N);
            vec3 H = normalize(L+E);
            vec3 DiffuseComponent = lights[i].Color * DiffuseColor * sat(dot(N,L));
            vec3 SpecularComponent = lights[i].Color * SpecularColor * pow( sat(dot(N,H)), SpecularExp);
            FColor += vec3(DiffuseComponent*DiffTex.rgb + SpecularComponent);
            //FragColor = vec4((DiffuseComponent + AmbientColor)*DiffTex.rgb + SpecularComponent ,DiffTex.a);
            
        } else if(lights[i].Type == 2) {
            
            //SPOT
            vec3 L = normalize(lights[i].Position-Position);
            vec3 R = reflect(-L,N);
            vec3 H = normalize(L+E);
            
            float o = acos(dot(-lights[i].Direction, L));
            
            vec3 LightColor = lights[i].Color * (1-sat( (o-lights[i].SpotRadius.x) / (lights[i].SpotRadius.y - lights[i].SpotRadius.x) ));
            
            float dist = sqrt( pow((lights[i].Position-Position).x, 2) + pow((lights[i].Position-Position).y, 2) + pow((lights[i].Position-Position).z, 2) );
            float att = 1.0/( lights[i].Attenuation.x + lights[i].Attenuation.y * dist + lights[i].Attenuation.z * dist * dist );
            
            vec3 DiffuseComponent = LightColor * DiffuseColor * sat(dot(N,L));
            vec3 SpecularComponent = LightColor * SpecularColor * pow( sat(dot(N,H)), SpecularExp);
            FColor += vec3(DiffuseComponent*DiffTex.rgb + SpecularComponent);
            //FragColor = vec4((DiffuseComponent + AmbientColor)*DiffTex.rgb + SpecularComponent ,DiffTex.a);
            
        }
    }
    vec4 DiffTexNew = texture( DiffuseTexture, Texcoord);
    FColor += AmbientColor * DiffTexNew.rgb;
    FragColor = vec4(FColor, DiffTexNew.a);
    // FragColor = vec4(NewNormal, DiffTexNew.a);
}
