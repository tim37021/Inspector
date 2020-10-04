#version 130

attribute float vertexPosition;


uniform float leftRange = 0;
uniform float rightRange = 4096;
uniform float topRange = 1000000;
uniform float bottomRange = -1000000;

void main()
{
    float x = (gl_VertexID - leftRange) / (rightRange - leftRange) * 2 - 1;
    float y = (vertexPosition - bottomRange) / (topRange - bottomRange) * 2 - 1;
    
    gl_Position = vec4(x, y, 0, 1.0);
}