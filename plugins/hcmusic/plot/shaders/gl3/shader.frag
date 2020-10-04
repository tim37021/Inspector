#version 150 core

uniform vec3 mainColor;
out vec4 fragColor;

void main()
{
    //output color from material
    fragColor = vec4(mainColor,1.0);
}
