#version 120

uniform vec3 mainColor;

void main()
{
    //output color from material
    gl_FragColor = vec4(mainColor,1.0);
}
