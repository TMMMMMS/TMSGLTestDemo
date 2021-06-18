
//这个就是刚才从顶点着色器传过来的纹理坐标，注意这里最好直接复制过来，因为一个字母都不许差
varying lowp vec2 varyTextCoord;
//uniform属性 sampler2D代表的是声明纹理属性，就是说声明这个变量是纹理，他是以类似标识符的方式存储的
//也就是说不是把你真的纹理放进来了，而是给纹理声明了一个身份ID，由ID去索引相应的纹理
uniform sampler2D colorMap;

void main ()
{
    //内建变量gl_FragColor(纹理采样器，纹理坐标)
    //参数1 : 纹理的身份ID
    //参数2 : 纹理坐标。
    //内建函数会返回一个vec4类型的rgba值
    //它的作用就是读取纹素
    gl_FragColor = texture2D(colorMap, varyTextCoord);
}
