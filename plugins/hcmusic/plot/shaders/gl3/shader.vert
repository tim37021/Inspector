#version 330 core

in float vertexPosition;
uniform mat4 modelMatrix;
uniform mat4 mvp;

uniform float leftRange = 0;
uniform float rightRange = 4096;
uniform float topRange = 1000000;
uniform float bottomRange = -1000000;

void main()
{
    // Transform position, normal, and tangent to world coords
    //worldPosition = vec3(modelMatrix * vec4(vertexPosition, 1.0));


    // Calculate vertex position in clip coordinates
    
    float x = (gl_VertexID - leftRange) / (rightRange - leftRange) * 2 - 1;
    float y = (vertexPosition - bottomRange) / (topRange - bottomRange) * 2 - 1;

    gl_Position = vec4(x, y, 0, 1.0);
}