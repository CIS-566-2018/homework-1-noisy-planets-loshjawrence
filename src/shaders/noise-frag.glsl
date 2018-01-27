#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_NorGeom;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_ViewVec;
in float isWater;
in float shininessMap;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = fs_Col;

        // Calculate the diffuse term for Lambert shading
        vec3 NorGeom = normalize(vec3(fs_NorGeom));
        vec3 Nor = normalize(vec3(fs_Nor));
        vec3 LightVec = normalize(vec3(fs_LightVec));
        vec3 ViewVec = normalize(vec3(fs_ViewVec));
        float sideLight = dot(NorGeom, LightVec);
        float sideView = dot(NorGeom, ViewVec);

        //ambient
        vec3 ambient = 0.1f * fs_Col.rgb;

        //diffuse
        float diff = sideLight <= 0.f ? 0.f : max(dot(Nor, LightVec),0.f);
        vec3 diffuse = diff * fs_Col.rgb;
        
        //specular
        vec3 halfVec = normalize(LightVec + ViewVec);
        float  sameHemi = sideLight <= 0.f || sideView <= 0.f ? 0.f : 1.f;
        float specPower = pow(2.f, 13.f*shininessMap);
        float spec = pow(max(dot(halfVec, Nor), 0.f), specPower) * 1.f * isWater;

        // Compute final shaded color
        out_Col = vec4(diffuse + ambient + spec, fs_Col.a);
        //out_Col = vec4(spec, spec, spec, fs_Col.a);

}
