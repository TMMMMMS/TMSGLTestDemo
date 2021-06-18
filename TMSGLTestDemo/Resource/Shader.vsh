
//顶点坐标
attribute vec4 position;
//纹理坐标
attribute vec2 textCoordinate;
//varying是一个标记，声明了这个变量是用来在vsh和fsh文件之间传递的变量
//lowp是指这个二维向量的单位:GLFloat，它的精度
//这个参数是存储纹理坐标的
varying lowp vec2 varyTextCoord;

void main ()
{
    //把纹理坐标值赋值给传递变量，由传递变量将纹理坐标传输到片元着色器
    /*
     跑起来会发现图片是倒的, 因为纹理坐标左下角为(0,0), 所以我们需要对图片进行翻转.https://www.jianshu.com/p/0a0fd8015bd3
     */
//    varyTextCoord = textCoordinate;
    varyTextCoord = vec2(textCoordinate.x,1.0-textCoordinate.y);
    //gl_Position是GLSL的内建变量，也就是GLSL已经创建好了的，用来保存顶点坐标的变量
    gl_Position = position;
}

