#version 450 compatibility

// outputs to fragment shader

out vec4 texcoord;

void main()
{
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0;
}