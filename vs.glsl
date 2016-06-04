#version 450 core

layout(std140) uniform TransformBlock
{
    mat4 matrix;
} transform;

layout (location = 0) in vec3 position;

void main(void)
{
    vec4 transformed = transform.matrix * vec4(position, 1.0);
    gl_Position = transformed;
}
