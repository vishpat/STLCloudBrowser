attribute vec4 position;
attribute vec3 normal;

varying lowp vec4 colorVarying;

uniform mat4 modelViewProjectionMatrix;
uniform mat3 normalMatrix;

struct lightSource
{
    vec4 position;
    vec4 diffuse;
};
lightSource light0 = lightSource(vec4(-1.0, 1.0, -1.0, 0.0), vec4(1.0, 1.0, 1.0, 1.0));

struct material
{
    vec4 diffuse;
};
material mymaterial = material(vec4(0.8, 0.8, 0.8, 1.0));

void main()
{
    vec3 eyeNormal = normalize(normalMatrix * normal);
    vec3 lightPosition = vec3(0.0, 0.0, 1.0);
    vec3 diffuseReflection = vec3(light0.diffuse) * vec3(mymaterial.diffuse) * max(0.0, dot(eyeNormal, lightPosition));
    
    colorVarying = vec4(diffuseReflection, 1.0);
    gl_Position = modelViewProjectionMatrix * position;
}
