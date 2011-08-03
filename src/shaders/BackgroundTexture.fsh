varying highp vec2 textureCoordinate;

uniform sampler2D image;

void main()
{
    gl_FragColor = texture2D(image, textureCoordinate);
}
