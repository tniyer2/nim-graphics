#version 330 core
layout (location = 0) in vec3 aPos;

out vec3 vertexColor;

uniform mat4 transform;

void main()
{
    gl_Position = transform * vec4(aPos, 1.0);
    vertexColor = vec3(0.5, 0.0, 0.0);
}
